defmodule Absinthe.Middleware.Async do
  @moduledoc """
  This plugin enables asynchronous execution of a field.

  See also `Absinthe.Resolution.Helpers.async/1`

  # Example Usage:

  Using the `Absinthe.Resolution.Helpers.async/1` helper function:
  ```elixir
  field :time_consuming, :thing do
    resolve fn _, _, _ ->
      async(fn ->
        {:ok, long_time_consuming_function()}
      end)
    end
  end
  ```

  Using the bare plugin API
  ```elixir
  field :time_consuming, :thing do
    resolve fn _, _, _ ->
      task = Task.async(fn ->
        {:ok, long_time_consuming_function()}
      end)
      {:middleware, #{__MODULE__}, task}
    end
  end
  ```

  This module also serves as an example for how to build middleware that uses the
  resolution callbacks.

  See the source code and associated comments for further details.
  """

  @behaviour Absinthe.Middleware
  @behaviour Absinthe.Plugin

  # A function has handed resolution off to this middleware. The first argument
  # is the current resolution struct. The second argument is the function to
  # execute asynchronously, and opts we'll want to use when it is time to await
  # the task.
  #
  # This function suspends resolution, and sets the async flag true in the resolution
  # accumulator. This will be used later to determine whether we need to run resolution
  # again.
  #
  # This function inserts additional middleware into the remaining middleware
  # stack for this field. On the next resolution pass, we need to `Task.await` the
  # task so we have actual data. Thus, we prepend this module to the middleware stack.
  def call(%{state: :unresolved} = res, {fun, opts}) when is_function(fun) do
    task =
      async(fn ->
        :telemetry.span([:absinthe, :middleware, :async, :task], %{}, fn -> {fun.(), %{}} end)
      end)

    call(res, {task, opts})
  end

  def call(%{state: :unresolved} = res, {task, opts}) do
    task_data = {task, opts}

    %{
      res
      | state: :suspended,
        acc: Map.put(res.acc, __MODULE__, true),
        middleware: [{__MODULE__, task_data} | res.middleware]
    }
  end

  def call(%{state: :unresolved} = res, %Task{} = task), do: call(res, {task, []})

  # This is the clause that gets called on the second pass. There's very little
  # to do here. We just need to await the task started in the previous pass.
  #
  # Finally, we apply the result to the resolution using a helper function that ensures
  # we handle the different tuple results.
  #
  # The `put_result` function handles setting the appropriate state.
  # If the result is an `{:ok, value} | {:error, reason}` tuple it will set
  # the state to `:resolved`, and if it is another middleware tuple it will
  # set the state to unresolved.
  def call(%{state: :suspended} = res, {task, opts}) do
    result = Task.await(task, opts[:timeout] || 30_000)

    res
    |> Absinthe.Resolution.put_result(result)
  end

  # We must set the flag to false because if a previous resolution iteration
  # set it to true it needs to go back to false now. It will be set
  # back to true if any field uses this plugin again.
  def before_resolution(exec) do
    put_in(exec.acc[__MODULE__], false)
  end

  # Nothing to do after resolution for this plugin, so we no-op
  def after_resolution(exec), do: exec

  # If the flag is set we need to do another resolution phase.
  # otherwise, we do not
  def pipeline(pipeline, exec) do
    case exec.acc do
      %{__MODULE__ => true} ->
        [Absinthe.Phase.Document.Execution.Resolution | pipeline]

      _ ->
        pipeline
    end
  end

  # Optionally use `async/1` function from `opentelemetry_process_propagator` if available
  if Code.ensure_loaded?(OpentelemetryProcessPropagator.Task) do
    @spec async((() -> any)) :: Task.t()
    defdelegate async(fun), to: OpentelemetryProcessPropagator.Task
  else
    @spec async((() -> any)) :: Task.t()
    defdelegate async(fun), to: Task
  end
end
