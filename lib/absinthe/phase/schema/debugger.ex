defmodule Absinthe.Phase.Schema.Debugger do
  @moduledoc false

  use Absinthe.Phase
  alias Absinthe.Blueprint

  def run(blueprint, _opts) do
    blueprint = Blueprint.prewalk(blueprint, &add_reference_type_name(&1, blueprint))
    {:ok, blueprint}
  end

  def add_reference_type_name(
        %Blueprint.Schema.ObjectTypeDefinition{interfaces: interfaces} = before,
        blueprint
      ) do
    interface_names =
      Enum.map(interfaces, fn identifier ->
        case Absinthe.Blueprint.Schema.lookup_type(blueprint, identifier) do
          %{name: name} -> name
        end
      end)

    %{before | interface_names: interface_names}
  end

  def add_reference_type_name(
        %Blueprint.TypeReference.NonNull{of_type: of_type} = before,
        blueprint
      )
      when is_atom(of_type) do
    case Absinthe.Blueprint.Schema.lookup_type(blueprint, of_type) do
      %{name: name} -> %{before | type_name: name}
      nil -> %{before | type_name: scalar_type_name(of_type)}
    end
  end

  def add_reference_type_name(%Blueprint.TypeReference.List{of_type: of_type} = before, blueprint)
      when is_atom(of_type) do
    case Absinthe.Blueprint.Schema.lookup_type(blueprint, of_type) do
      %{name: name} -> %{before | type_name: name}
      nil -> %{before | type_name: scalar_type_name(of_type)}
    end
  end

  def add_reference_type_name(node, _blueprint), do: node

  defp scalar_type_name(:integer), do: "Int"
  defp scalar_type_name(scalar), do: scalar |> to_string() |> Macro.camelize()
end
