defmodule Absinthe.Phase.Schema.Validation.TypeReferencesExist do
  @moduledoc false

  use Absinthe.Phase
  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Schema

  # TODO: actually do the type reference validation.
  # Right now it just handles topsorting the types by import
  def run(blueprint, _opts) do
    blueprint = Blueprint.prewalk(blueprint, &validate_schema/1)
    {:ok, blueprint}
  end

  def validate_schema(%Schema.SchemaDefinition{} = schema) do
    types = for type <- schema.type_definitions, into: MapSet.new(), do: type.identifier
    schema = Blueprint.prewalk(schema, &validate_types(&1, types))
    {:halt, schema}
  end

  def validate_schema(node), do: node

  def validate_types(type, types) do
    type
  end
end
