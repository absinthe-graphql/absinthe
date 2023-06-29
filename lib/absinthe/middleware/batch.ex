defmodule Absinthe.Middleware.Batch do
  @moduledoc """
  Batch the resolution of multiple fields.

  ## Motivation
  Consider the following graphql query:
  ```
  {
    posts {
      author {
        name
      }
    }
  }
  ```

  `posts` returns a list of `post` objects, which has an associated `author` field.
  If the `author` field makes a call to the database we have the classic N + 1 problem.
  What we want is a way to load all authors for all posts in one database request.

  This plugin provides this, without any eager loading at the parent level. That is,
  the code for the `posts` field does not need to do anything to facilitate the
  efficient loading of its children.

  ## Example Usage
  The API for this plugin is a little on the verbose side because it is not specific
  to any particular batching mechanism. That is, this API is just as useful for an Ecto
  based DB as it is for talking to S3 or the File System. Thus we anticipate people
  (including ourselves) will be creating additional functions more tailored to each
  of those specific use cases.

  Here is an example using the `Absinthe.Resolution.Helpers.batch/3` helper.
  ```elixir
  object :post do
    field :name, :string
    field :author, :user do
      resolve fn post, _, _ ->
        batch({__MODULE__, :users_by_id}, post.author_id, fn batch_results ->
          {:ok, Map.get(batch_results, post.author_id)}
        end)
      end
    end
  end

  def users_by_id(_, user_ids) do
    users = Repo.all from u in User, where: u.id in ^user_ids
    Map.new(users, fn user -> {user.id, user} end)
  end
  ```

  Let's look at this piece by piece:
  - `{__MODULE__, :users_by_id}`: is the batching function which will be used. It must
  be a 2 arity function. For details see the `batch_fun` typedoc.
  - `post.author_id`: This is the information to be aggregated. The aggregated values
  are the second argument to the batching function.
  - `fn batch_results`: This function takes the results from the batching function.
  it should return one of the resolution function values.
  """

  @behaviour Absinthe.Middleware
  @behaviour Absinthe.Plugin

  @typedoc """
  The function to be called with the aggregate batch information.

  It comes in both a 2 tuple and 3 tuple form. The first two elements are the module
  and function name. The third element is an arbitrary parameter that is passed
  as the first argument to the batch function.

  For example, one could parameterize the `users_by_id` function from the moduledoc
  to make it more generic. Instead of doing `{__MODULE__, :users_by_id}` you could do
  `{__MODULE__, :by_id, User}`. Then the function would be:

  ```elixir
  def by_id(model, ids) do
    model
    |> where([m], m.id in ^ids)
    |> Repo.all()
    |> Map.new(&{&1.id, &1})
  end
  ```
  It could also be used to set options unique to the execution of a particular
  batching function.
  """
  @type batch_fun :: {module, atom} | {module, atom, term}

  @type post_batch_fun :: (term -> Absinthe.Type.Field.result())

  def before_resolution(exec) do
    case exec.acc do
      %{__MODULE__ => _} ->
        put_in(exec.acc[__MODULE__][:input], [])

      _ ->
        put_in(exec.acc[__MODULE__], %{input: [], output: %{}})
    end
  end

  def call(%{state: :unresolved} = res, {batch_key, field_data, post_batch_fun, batch_opts}) do
    acc = res.acc

    acc =
      update_in(acc[__MODULE__][:input], fn
        nil -> [{{batch_key, batch_opts}, field_data}]
        data -> [{{batch_key, batch_opts}, field_data} | data]
      end)

    %{
      res
      | state: :suspended,
        middleware: [{__MODULE__, {batch_key, post_batch_fun}} | res.middleware],
        acc: acc
    }
  end

  def call(%{state: :suspended} = res, {batch_key, post_batch_fun}) do
    batch_data_for_fun =
      res.acc
      |> Map.fetch!(__MODULE__)
      |> Map.fetch!(:output)
      |> Map.fetch!(batch_key)

    res
    |> Absinthe.Resolution.put_result(post_batch_fun.(batch_data_for_fun))
  end

  def after_resolution(exec) do
    output = do_batching(exec.acc[__MODULE__][:input])
    put_in(exec.acc[__MODULE__][:output], output)
  end

  defp do_batching(input) do
    input
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Enum.map(fn {{batch_fun, batch_opts}, batch_data} ->
      system_time = System.system_time()
      start_time_mono = System.monotonic_time()

      task =
        async(fn ->
          {batch_fun, call_batch_fun(batch_fun, batch_data)}
        end)

      metadata = emit_start_event(system_time, batch_fun, batch_opts, batch_data)

      {batch_opts, task, start_time_mono, metadata}
    end)
    |> Map.new(fn {batch_opts, task, start_time_mono, metadata} ->
      timeout = Keyword.get(batch_opts, :timeout, 5_000)
      result = Task.await(task, timeout)

      end_time_mono = System.monotonic_time()
      duration = end_time_mono - start_time_mono
      emit_stop_event(duration, end_time_mono, metadata, result)

      result
    end)
  end

  @batch_start [:absinthe, :middleware, :batch, :start]
  @batch_stop [:absinthe, :middleware, :batch, :stop]
  defp emit_start_event(system_time, batch_fun, batch_opts, batch_data) do
    id = :erlang.unique_integer()

    metadata = %{
      id: id,
      telemetry_span_context: id,
      batch_fun: batch_fun,
      batch_opts: batch_opts,
      batch_data: batch_data
    }

    :telemetry.execute(
      @batch_start,
      %{system_time: system_time},
      metadata
    )

    metadata
  end

  defp emit_stop_event(duration, end_time_mono, metadata, result) do
    :telemetry.execute(
      @batch_stop,
      %{duration: duration, end_time_mono: end_time_mono},
      Map.put(metadata, :result, result)
    )
  end

  defp call_batch_fun({module, fun}, batch_data) do
    call_batch_fun({module, fun, []}, batch_data)
  end

  defp call_batch_fun({module, fun, config}, batch_data) do
    apply(module, fun, [config, batch_data])
  end

  # If the flag is set we need to do another resolution phase.
  # otherwise, we do not
  def pipeline(pipeline, exec) do
    case exec.acc[__MODULE__][:input] do
      [_ | _] ->
        [Absinthe.Phase.Document.Execution.Resolution | pipeline]

      _ ->
        pipeline
    end
  end

  # Optionally use `async/1` function from `opentelemetry_process_propagator` if available
  if Code.ensure_loaded?(OpentelemetryProcessPropagator.Task) do
    @spec async((-> any)) :: Task.t()
    defdelegate async(fun), to: OpentelemetryProcessPropagator.Task
  else
    @spec async((-> any)) :: Task.t()
    defdelegate async(fun), to: Task
  end
end
