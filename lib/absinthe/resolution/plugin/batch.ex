defmodule Absinthe.Resolution.Plugin.Batch do
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
    Repo.all from u in User, where: u.id in ^user_ids
  end
  ```

  Let's look at this piece by piece:
  - `{__MODULE__, :users_by_id}`: is the batching function which will be used. It must
  be a 2 arity function. For details see the `batch_fun` typedoc.
  - `post.author_id`: This is the information to be aggregated. The aggregated values
  are the second argument to the batching function.
  - `fn batch_results`: This function takes the results from the batching function.
  it should return one of the resolution function values.

  Clearly some of this could be derived for ecto functions. We hope to have an
  Absinthe.Ecto library that might provide an API more like:
  ```elixir
  field :author, :user, resolve: belongs_to(:author)
  ```

  Such a function could be easily built upon the API of this module.
  """

  @behaviour Absinthe.Resolution.Plugin

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
    Repo.al from m in model, where: m.id in ^ids
  end
  ```
  It could also be used to set options unique to the execution of a particular
  batching function.
  """
  @type batch_fun :: {module, atom} | {module, atom, term}

  @type post_batch_fun :: (term -> Absinthe.Type.Field.resolver_output)

  def before_resolution(acc) do
    case acc do
      %{__MODULE__ => _} ->
        put_in(acc[__MODULE__][:input], [])
      _ ->
        Map.put(acc, __MODULE__, %{input: [], output: %{}})
    end
  end

  def init({batch_fun, field_data, post_batch_fun, batch_opts}, acc) do
    acc = update_in(acc[__MODULE__][:input], fn
      nil -> [{{batch_fun, batch_opts}, field_data}]
      data -> [{{batch_fun, batch_opts}, field_data} | data]
    end)

    {{batch_fun, post_batch_fun}, acc}
  end

  def after_resolution(acc) do
    output = do_batching(acc[__MODULE__][:input])
    put_in(acc[__MODULE__][:output], output)
  end

  defp do_batching(input) do
    input
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Enum.map(fn {{batch_fun, batch_opts}, batch_data}->
      {batch_opts, Task.async(fn ->
        {batch_fun, call_batch_fun(batch_fun, batch_data)}
      end)}
    end)
    |> Map.new(fn {batch_opts, task} ->
      timeout = Keyword.get(batch_opts, :timeout, 5_000)
      Task.await(task, timeout)
    end)
  end

  defp call_batch_fun({module, fun}, batch_data) do
    call_batch_fun({module, fun, []}, batch_data)
  end
  defp call_batch_fun({module, fun, config}, batch_data) do
    apply(module, fun, [config, batch_data])
  end

  # If the flag is set we need to do another resolution phase.
  # otherwise, we do not
  def pipeline(pipeline, acc) do
    case acc[__MODULE__][:input] do
      [_|_] ->
        [Absinthe.Phase.Document.Execution.Resolution | pipeline]
      _ ->
        pipeline
    end
  end

  def resolve({batch_fun, post_batch_fun}, acc) do
    batch_data_for_fun =
      acc
      |> Map.fetch!(__MODULE__)
      |> Map.fetch!(:output)
      |> Map.fetch!(batch_fun)

    {post_batch_fun.(batch_data_for_fun), acc}
  end
end
