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
    {:ok, update_in(bp_root.execution.result, &to_tree/1)}
  end

  defp to_tree(%{0 => result}) do
    result |> length |> IO.inspect(label: :nodes)
    # result |> view
    compact(result, %{})
  end

  defp compact([{:top, %Result.Object{} = top}], buffers) do
    %{top | fields: Map.fetch!(buffers, top.ref)}
  end

  defp compact([{parent, %Result.Leaf{} = result} | rest], buffers) do
    buffers = Map.update(buffers, parent, [result], &[result | &1])
    compact(rest, buffers)
  end

  defp compact([{parent, %Result.List{} = result} | rest], buffers) do
    {values, buffers} = Map.pop(buffers, result.ref, [])
    result = %{result | values: values}
    buffers = Map.update(buffers, parent, [result], &[result | &1])
    compact(rest, buffers)
  end

  defp compact([{parent, %Result.Object{} = result} | rest], buffers) do
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
