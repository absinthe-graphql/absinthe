defmodule Absinthe.Phase.Document.Execution.Compact do
  @moduledoc false

  # Runs resolution functions in a blueprint.
  #
  # Blueprint results are placed under `blueprint.result.execution`. This is
  # because the results form basically a new tree from the original blueprint.

  alias Absinthe.{Blueprint, Type, Phase}
  alias Blueprint.{Result, Execution}

  alias Absinthe.Phase
  use Absinthe.Phase

  @spec run(Blueprint.t(), Keyword.t()) :: Phase.result_t()
  def run(bp_root, options \\ []) do
    {:ok, update_in(bp_root.execution.result, &compact/1)}
  end

  defp compact(result) when is_list(result) do
    # result |> view
    compact(result, %{})
  end

  defp compact(result) do
    result |> IO.inspect()
  end

  defp compact([{:result, :top, %Result.Object{} = top}], buffers) do
    %{top | fields: Map.fetch!(buffers, top.ref)}
  end

  defp compact([{:result, parent, %Result.Leaf{} = result} | rest], buffers) do
    buffers = Map.update(buffers, parent, [result], &[result | &1])
    compact(rest, buffers)
  end

  defp compact([{:result, parent, %Result.List{} = result} | rest], buffers) do
    {values, buffers} = Map.pop(buffers, result.ref, [])
    result = %{result | values: values}
    buffers = Map.update(buffers, parent, [result], &[result | &1])
    compact(rest, buffers)
  end

  defp compact([{:result, parent, %Result.Object{} = result} | rest], buffers) do
    {fields, buffers} = Map.pop(buffers, result.ref, [])
    result = %{result | fields: fields}
    buffers = Map.update(buffers, parent, [result], &[result | &1])
    compact(rest, buffers)
  end

  defp do_compact([%Result.Object{} = object | rest]) do
    raise "boom"
  end

  defp view(val) do
    val
    |> Enum.map(fn
      {:result, ref, result} ->
        {:result, ref, Map.update!(result, :emitter, fn %{flags: flags} -> flags end)}
    end)
    |> IO.inspect()
  end
end
