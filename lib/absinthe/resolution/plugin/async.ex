defmodule Absinthe.Resolution.Plugin.Async do
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

  @behaviour Absinthe.Resolution.Plugin

  # We must set the flag to false because if a previous resolution iteration
  # set it to true it needs to go back to false now. It will be set
  # back to true if any field uses this plugin again.
  def before_resolution(acc) do
    Map.put(acc, __MODULE__, false)
  end

  # A field has used this plugin, we need to set our flag on the accumulator true
  def init(task, acc) do
    {task, Map.put(acc, __MODULE__, true)}
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

  # In a later resolution phase we've now come across an invocation of this plugin
  # left behind by a prior phase. It needs to be resolved to a real value now.
  def resolve({task, opts}, acc) do
    {Task.await(task, Keyword.get(opts, :timeout, 30_000)), acc}
  end
end
