defmodule Absinthe.Phase.Schema.Debugger do
  @moduledoc false

  use Absinthe.Phase
  alias Absinthe.Blueprint

  def run(blueprint, _opts) do
    blueprint = Blueprint.prewalk(blueprint, &inject_name(&1, blueprint))
    {:ok, blueprint}
  end

  def inject_name(
        %Blueprint.Schema.ObjectTypeDefinition{interfaces: interfaces} = object_type,
        blueprint
      ) do
    interface_types = Enum.map(interfaces, &type_reference_name(&1, blueprint))
    %{object_type | interface_types: interface_types}
  end

  @replace_type_reference [Blueprint.TypeReference.List, Blueprint.TypeReference.NonNull]
  def inject_name(%struct{of_type: identifier} = reference, blueprint)
      when is_atom(identifier) and struct in @replace_type_reference do
    %{reference | of_type: type_reference_name(identifier, blueprint)}
  end

  def inject_name(node, _blueprint), do: node

  defp type_reference_name(%Blueprint.TypeReference.Name{} = reference, _blueprint) do
    reference
  end

  defp type_reference_name(identifier, blueprint) do
    %Blueprint.TypeReference.Name{name: type_name(identifier, blueprint)}
  end

  defp type_name(identifier, blueprint) do
    case Absinthe.Blueprint.Schema.lookup_type(blueprint, identifier) do
      %{name: name} -> name
      nil -> scalar_type_name(identifier)
    end
  end

  defp scalar_type_name(:integer), do: "Int"
  defp scalar_type_name(scalar), do: scalar |> to_string() |> Macro.camelize()
end
