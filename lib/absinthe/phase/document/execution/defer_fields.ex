defmodule Absinthe.Phase.Document.Execution.DeferFields do
  @moduledoc false

  # Strips out deferred fields from the current result and places them
  # in continuations.

  alias Absinthe.Phase.Document.Execution.Resolution
  alias Absinthe.{Blueprint, Phase, Resolution}
  alias Blueprint.Continuation
  alias Blueprint.Result.List

  use Absinthe.Phase

  @spec run(Blueprint.t(), Keyword.t()) :: Phase.result_t()
  def run(bp_root, _options \\ []) do
    result = strip_deferred(bp_root, bp_root.execution.result)

    {:ok, %{bp_root | execution: %{bp_root.execution | result: result}}}
  end

  defp strip_deferred(bp_root, %{fields: _} = object) do
    strip_nested(bp_root, object, :fields)
  end

  defp strip_deferred(bp_root, %List{} = object) do
    strip_nested(bp_root, object, :values)
  end

  defp strip_deferred(bp_root, fields) when is_list(fields) do
    fields
    |> Enum.reduce(
      {[], []},
      fn f, acc -> do_strip_deferred(bp_root, f, acc) end
    )
  end

  defp strip_deferred(_bp_root, other), do: other

  defp strip_nested(bp_root, object, sub_object_field) do
    {continuations, remaining} = strip_deferred(bp_root, Map.get(object, sub_object_field))

    object
    |> Map.put(sub_object_field, Enum.reverse(remaining))
    |> Map.put(:continuations, object.continuations ++ Enum.reverse(continuations))
  end

  defp do_strip_deferred(
         bp_root,
         %Resolution{state: :suspended, acc: %{deferred_res: res}},
         {deferred, remaining}
       ) do
    continuation = %Continuation{
      phase_input: %{
        resolution: %{res | state: :unresolved},
        execution: bp_root.execution
      },
      pipeline: [
        Phase.Document.Execution.DeferredResolution,
        Phase.Document.Execution.DeferFields,
        Phase.Document.Result
      ]
    }

    {[continuation | deferred], remaining}
  end

  defp do_strip_deferred(_bp_root, %Resolution{} = r, {deferred, remaining}) do
    {deferred, [r | remaining]}
  end

  defp do_strip_deferred(bp_root, %{fields: _} = object, acc) do
    do_strip_nested(bp_root, object, :fields, acc)
  end

  defp do_strip_deferred(bp_root, %List{} = object, acc) do
    do_strip_nested(bp_root, object, :values, acc)
  end

  defp do_strip_deferred(_bp_root, object, {deferred, remaining}) do
    {deferred, [object | remaining]}
  end

  defp do_strip_nested(bp_root, object, sub_object_field, {deferred, remaining}) do
    {d, r} = strip_deferred(bp_root, Map.get(object, sub_object_field))
    object = Map.put(object, sub_object_field, Enum.reverse(r))
    {d ++ deferred, [object | remaining]}
  end
end
