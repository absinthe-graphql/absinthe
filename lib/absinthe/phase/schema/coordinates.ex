defmodule Absinthe.Phase.Schema.Coordinates do
  @moduledoc false
  # Schema phase that populates schema coordinates

  use Absinthe.Phase

  alias Absinthe.Blueprint.Schema
  alias Absinthe.Utils

  def run(blueprint, _options \\ []) do
    {:ok, Absinthe.Blueprint.prewalk(blueprint, &process/1)}
  end

  # Nodes without ancestors
  defp process(%Schema.SchemaDefinition{coordinate: nil} = node) do
    %{node | coordinate: "Schema"}
  end

  defp process(%Schema.ObjectTypeDefinition{coordinate: nil} = node) do
    %{node | coordinate: node.name, fields: Enum.map(node.fields, &process(&1, node.name))}
  end

  defp process(%Schema.InputObjectTypeDefinition{coordinate: nil} = node) do
    %{node | coordinate: node.name, fields: Enum.map(node.fields, &process(&1, node.name))}
  end

  defp process(%Schema.EnumTypeDefinition{coordinate: nil} = node) do
    %{node | coordinate: node.name, values: Enum.map(node.values, &process(&1, node.name))}
  end

  defp process(node), do: node

  # Nodes with ancestors
  defp process(%Schema.FieldDefinition{coordinate: nil, name: name} = node, type_name) do
    coordinate = "#{type_name}.#{Utils.camelize(name, lower: true)}"
    arguments = Enum.map(node.arguments, &process(&1, coordinate))
    %{node | coordinate: coordinate, arguments: arguments}
  end

  defp process(%Schema.InputValueDefinition{coordinate: nil, name: name} = node, coordinate) do
    %{node | coordinate: "#{coordinate}(#{Utils.camelize(name, lower: true)}:)"}
  end

  defp process(%Schema.EnumValueDefinition{coordinate: nil, name: name} = node, enum_name) do
    %{node | coordinate: "#{enum_name}.#{name}"}
  end

  defp process(node, _), do: node
end
