defmodule Absinthe.Phase.Schema.Validation.TypeReferencesExist do
  @moduledoc false

  # Checks whether all types referenced in the schema exist and
  # are of the correct kind.

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
    check_or_error(field, field.type, types, inner_type: true)
  end

  def validate_types(%Blueprint.Schema.ObjectTypeDefinition{} = object, types) do
    object
    |> check_types(:interfaces, &check_or_error(&2, &1, types, inner_type: false))
    |> check_types(:imports, fn {type, _}, obj ->
      check_or_error(obj, type, types, inner_type: false)
    end)
  end

  def validate_types(%Blueprint.Schema.InterfaceTypeDefinition{} = interface, types) do
    interface
    |> check_types(:interfaces, &check_or_error(&2, &1, types, inner_type: false))
    |> check_types(:imports, fn {type, _}, obj ->
      check_or_error(obj, type, types, inner_type: false)
    end)
  end

  def validate_types(%Blueprint.Schema.InputObjectTypeDefinition{} = object, types) do
    check_types(object, :imports, fn {type, _}, obj ->
      check_or_error(obj, type, types, inner_type: false)
    end)
  end

  def validate_types(%Blueprint.Schema.InputValueDefinition{} = input, types) do
    check_or_error(input, input.type, types, inner_type: true)
  end

  def validate_types(%Blueprint.Schema.UnionTypeDefinition{} = union, types) do
    check_types(union, :types, &check_or_error(&2, &1, types, inner_type: false))
  end

  def validate_types(%Blueprint.Schema.TypeExtensionDefinition{} = extension, types) do
    case extension.definition do
      %Blueprint.Schema.SchemaDeclaration{} = declaration ->
        declaration

      definition ->
        check_or_error(extension, definition.identifier, types, inner_type: false)
    end
  end

  @no_types [
    Blueprint.Schema.DirectiveDefinition,
    Blueprint.Schema.EnumTypeDefinition,
    Blueprint.Schema.EnumValueDefinition,
    Blueprint.Schema.ScalarTypeDefinition,
    Blueprint.Schema.SchemaDefinition,
    Blueprint.Schema.SchemaDeclaration,
    Blueprint.TypeReference.NonNull,
    Blueprint.TypeReference.ListOf,
    Blueprint.TypeReference.Name,
    Blueprint.TypeReference.Identifier
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

  defp check_or_error(thing, type, types, opts) when is_list(opts) do
    check_or_error(thing, type, types, Map.new(opts))
  end

  defp check_or_error(thing, type, types, %{inner_type: true}) do
    type = inner_type(type)
    check_or_error(thing, type, types, inner_type: false)
  end

  defp check_or_error(thing, type, types, %{inner_type: false}) do
    case unwrapped?(type) do
      {:ok, type} ->
        if type in types do
          thing
        else
          put_error(thing, error(thing, type))
        end

      :error ->
        put_error(thing, wrapped_error(thing, type))
    end
  end

  defp inner_type(value) when is_binary(value) or is_atom(value) do
    value
  end

  defp inner_type(%{of_type: type}) do
    inner_type(type)
  end

  defp inner_type(%Absinthe.Blueprint.TypeReference.Name{name: name}) do
    name
  end

  defp unwrapped?(value) when is_binary(value) or is_atom(value), do: {:ok, value}
  defp unwrapped?(%Absinthe.Blueprint.TypeReference.Name{name: name}), do: {:ok, name}
  defp unwrapped?(%Absinthe.Blueprint.TypeReference.Identifier{id: id}), do: {:ok, id}
  defp unwrapped?(_), do: :error

  defp error(thing, type) do
    %Absinthe.Phase.Error{
      message: message(thing, type),
      locations: [thing.__reference__.location],
      phase: __MODULE__
    }
  end

  defp message(%Blueprint.Schema.TypeExtensionDefinition{}, type) do
    """
    In type extension the target type #{inspect(type)} is not
    defined in your schema.

    Types must exist if referenced.
    """
  end

  defp message(thing, type) do
    kind = Absinthe.Blueprint.Schema.struct_to_kind(thing.__struct__)
    artifact_name = String.capitalize(thing.name)

    """
    In #{kind} #{artifact_name}, #{inspect(type)} is not defined in your schema.

    Types must exist if referenced.
    """
  end

  defp wrapped_error(thing, type) do
    %Absinthe.Phase.Error{
      message: wrapped_message(thing, type),
      locations: [thing.__reference__.location],
      phase: __MODULE__
    }
  end

  defp wrapped_message(thing, type) do
    kind = Absinthe.Blueprint.Schema.struct_to_kind(thing)
    artifact_name = String.capitalize(thing.name)

    """
    In #{kind} #{artifact_name}, cannot accept a non-null or a list type.

    Got: #{Blueprint.TypeReference.name(type)}

    """
  end
end
