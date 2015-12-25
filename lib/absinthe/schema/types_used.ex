defmodule Absinthe.Schema.TypesUsed do

  alias Absinthe.Schema
  alias Absinthe.Traversal
  alias Absinthe.Type

  @type acc_t :: {%{atom => Type.t}, %{atom => Type.t}}

  def calculate(%{type_module: type_module, types_available: types_available} = schema) do
    case Traversal.reduce(schema, schema, {types_available, [], %{}}, &collect_types/3) do
      {_, errors, _} when length(errors) > 0 ->
        raise "Errors occurred processing types used: " <> Enum.join(errors, " / ")
      {_, _, result} ->
        result
    end
  end

  # TODO: Support abstract types
  @spec collect_types(Traversal.Node.t, Schema.t, acc_t) :: Traversal.instruction_t
  defp collect_types(%{type: possibly_wrapped_type}, schema, {avail, errors, collect} = acc) do
    type = possibly_wrapped_type |> Type.unwrap
    case {collect[type], avail[type]} do
      # Invalid
      {nil, nil} ->
        avail_names = avail |> Map.keys |> Enum.join(", ")
        {:prune, {avail, ["Missing type #{type}; not found in #{avail_names}"|errors], collect}}
      # Not yet collected
      {nil, found} ->
        {:ok, {avail, errors, collect |> Map.put(type, found)}}
      # Already collected
      {found, _} ->
        {:prune, acc}
    end
  end
  defp collect_types(_node, _schema, acc) do
    {:ok, acc}
  end

end
