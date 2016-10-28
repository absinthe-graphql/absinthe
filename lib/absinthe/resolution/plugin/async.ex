defmodule Absinthe.Resolution.Plugin.Async do
  defstruct [
    :task,
  ]

  def before_resolution(acc) do
    Map.put(acc, __MODULE__, false)
  end

  def after_resolution(acc), do: acc

  def add_phases(pipeline, %{__MODULE__ => true}) do
    [Absinthe.Phase.Document.Execution.Resolution | pipeline]
  end
  def add_phases(pipeline, _), do: pipeline

  def init(async, acc) do
    {async, Map.put(acc, __MODULE__, true)}
  end

  def resolve(%{task: task}, acc) do
    {Task.await(task), acc}
  end
end
