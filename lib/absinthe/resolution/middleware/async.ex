defmodule Absinthe.Resolution.Middleware.Async do
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
      end
      {:plugin, #{__MODULE__}, task}
    end
  end
  ```

  This module also serves as an example for how to build a basic resolution plugin.
  See the source code and associated comments for further details.
  """

  @behaviour Absinthe.Resolution.Middleware


  def call(%{state: :cont} = res, task_data) do
    %{res |
      state: :suspend,
      acc: Map.put(res.acc, __MODULE__, true),
      middleware: [{__MODULE__, task_data} | res.middleware]
    }
  end

  def call(%{state: :suspend} = res, {task, opts}) do
    %{res | state: :cont }
    |> Absinthe.Resolution.apply_result(Task.await(task, opts[:timeout] || 30_000))
  end

  # We must set the flag to false because if a previous resolution iteration
  # set it to true it needs to go back to false now. It will be set
  # back to true if any field uses this plugin again.
  def before_resolution(acc) do
    Map.put(acc, __MODULE__, false)
  end
  # Nothing to do after resolution for this plugin, so we no-op
  def after_resolution(acc), do: acc

  # If the flag is set we need to do another resolution phase.
  # otherwise, we do not
  def pipeline(pipeline, acc) do
    case acc do
      %{__MODULE__ => true} ->
        [Absinthe.Phase.Document.Execution.Resolution | pipeline]
      _ ->
        pipeline
    end
  end
end
