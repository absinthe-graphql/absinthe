defmodule Absinthe.Phase.Schema.Validation.TypeReferencesExist do
  @moduledoc false

  use Absinthe.Phase
  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Schema

  def run(blueprint, _opts) do
    blueprint = Blueprint.prewalk(blueprint, &validate_schema/1)

    {:ok, blueprint}
  end

  def validate_schema(%Schema.SchemaDefinition{} = schema) do
    types =
      schema.type_definitions
      |> Enum.flat_map(&[&1.name, &1.identifier])
      |> MapSet.new()

    schema = Blueprint.prewalk(schema, &validate_types(&1, types))
    {:halt, schema}
  end

  def validate_schema(node), do: node

  def validate_types(%Blueprint.Schema.FieldDefinition{} = field, types) do
    check_or_error(field, field.type, types)
  end

  def validate_types(%Blueprint.Schema.ObjectTypeDefinition{} = object, types) do
    object
    |> check_types(:interfaces, &check_or_error(&2, &1, types))
    |> check_types(:imports, fn {type, _}, obj -> check_or_error(obj, type, types) end)
  end

  def validate_types(%Blueprint.Schema.InterfaceTypeDefinition{} = interface, types) do
    check_types(interface, :interfaces, &check_or_error(&2, &1, types))
  end

  def validate_types(%Blueprint.Schema.InputObjectTypeDefinition{} = object, types) do
    check_types(object, :imports, fn {type, _}, obj -> check_or_error(obj, type, types) end)
  end

  def validate_types(%Blueprint.Schema.InputValueDefinition{} = input, types) do
    check_or_error(input, input.type, types)
  end

  def validate_types(%Blueprint.Schema.UnionTypeDefinition{} = union, types) do
    check_types(union, :types, &check_or_error(&2, &1, types))
  end

  @no_types [
    Blueprint.Schema.DirectiveDefinition,
    Blueprint.Schema.EnumTypeDefinition,
    Blueprint.Schema.EnumValueDefinition,
    Blueprint.Schema.InterfaceTypeDefinition,
    Blueprint.Schema.ObjectTypeDefinition,
    Blueprint.Schema.ScalarTypeDefinition,
    Blueprint.Schema.SchemaDefinition,
    Blueprint.TypeReference.NonNull,
    Blueprint.TypeReference.ListOf,
    Absinthe.Blueprint.TypeReference.Name
  ]
  def validate_types(%struct{} = type, _) when struct in @no_types do
    type
  end

  def validate_types(type, _) do
    type
  end

  defp check_types(entity, key, fun) do
    entity
    |> Map.fetch!(key)
    |> Enum.reduce(entity, fun)
  end

  defp check_or_error(thing, type, types) do
    type = unwrap(type)

    if type in types do
      thing
    else
      put_error(thing, error(thing, type))
    end
  end

  defp unwrap(value) when is_binary(value) or is_atom(value) do
    value
  end

  defp unwrap(%Absinthe.Blueprint.TypeReference.Name{name: name}) do
    name
  end

  defp unwrap(type) do
    unwrap_type = Absinthe.Blueprint.TypeReference.unwrap(type)

    if unwrap_type == type do
      type
    else
      unwrap(unwrap_type)
    end
  end

  defp error(thing, type) do
    artifact_name = String.capitalize(thing.name)

    %Absinthe.Phase.Error{
      message: """
      In #{artifact_name}, #{inspect(type)} is not defined in your schema.

      Types must exist if referenced.
      """,
      locations: [thing.__reference__.location],
      phase: __MODULE__
    }
  end
end
