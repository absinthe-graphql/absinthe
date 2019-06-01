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
    interface_names =
      Enum.map(interfaces, fn identifier ->
        case Absinthe.Blueprint.Schema.lookup_type(blueprint, identifier) do
          %{name: name} -> name
        end
      end)

    %{object_type | interface_names: interface_names}
  end

  def inject_name(%Blueprint.TypeReference.NonNull{of_type: identifier} = reference, blueprint)
      when is_atom(identifier) do
    %{reference | type_name: type_name(identifier, blueprint)}
  end

  def inject_name(%Blueprint.TypeReference.List{of_type: identifier} = reference, blueprint)
      when is_atom(identifier) do
    %{reference | type_name: type_name(identifier, blueprint)}
  end

  def inject_name(node, _blueprint), do: node

  defp type_name(identifier, blueprint) do
    case Absinthe.Blueprint.Schema.lookup_type(blueprint, identifier) do
      %{name: name} -> name
      nil -> scalar_type_name(identifier)
    end
  end

  defp scalar_type_name(:integer), do: "Int"
  defp scalar_type_name(scalar), do: scalar |> to_string() |> Macro.camelize()
end
