defmodule Absinthe.Phase.Schema.Modify do
  @moduledoc false

  use Absinthe.Phase
  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Schema

  def run(blueprint, opts \\ []) do
    {:ok, schema} = Keyword.fetch(opts, :schema)
    blueprint = Blueprint.prewalk(blueprint, &handle_modify(&1, schema))
    {:ok, blueprint}
  end

  @modifiable [
    Schema.DirectiveDefinition,
    Schema.EnumTypeDefinition,
    Schema.EnumValueDefinition,
    Schema.FieldDefinition,
    Schema.InputObjectTypeDefinition,
    Schema.InputValueDefinition,
    Schema.InterfaceTypeDefinition,
    Schema.ObjectTypeDefinition,
    Schema.ScalarTypeDefinition,
    Schema.UnionTypeDefinition
  ]
  def handle_modify(%node_module{} = node, schema) when node_module in @modifiable do
    schema.modify(node)
  end

  def handle_modify(node, _schema), do: node
end
