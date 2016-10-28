defmodule Absinthe.Resolution.Plugin.Async do
  defstruct [
    :task,
    :source,
    :blueprint,
    :info,
  ]

  def before_resolution(acc) do
    Map.put(acc, __MODULE__, false)
  end

  def after_resolution(acc), do: acc

  def add_phases(pipeline, %{__MODULE__ => true}) do
    [Absinthe.Phase.Document.Execution.Resolution | pipeline]
  end
  def add_phases(pipeline, _), do: pipeline

  def build_result(result, acc, blueprint, info, source) do
    result = %{result |
      source: source,
      blueprint: blueprint,
      info: info,
    }
    {result, Map.put(acc, __MODULE__, true)}
  end

  def walk_result(%{task: task}, acc) do
    {Task.await(task), acc}
  end
end
