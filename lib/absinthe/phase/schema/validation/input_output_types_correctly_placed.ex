defmodule Absinthe.Phase.Schema.Validation.InputOutputTypesCorrectlyPlaced do
  use Absinthe.Phase
  alias Absinthe.Blueprint

  def run(bp, _) do
    bp = Blueprint.prewalk(bp, &handle_schemas/1)
    {:ok, bp}
  end

  defp handle_schemas(%Blueprint.Schema.SchemaDefinition{} = schema) do
    types = Map.new(schema.type_definitions, &{&1.identifier, &1})
    schema = Blueprint.prewalk(schema, &validate_type(&1, types, schema))
    {:halt, schema}
  end

  defp handle_schemas(obj) do
    obj
  end

  defp validate_type(%Blueprint.Schema.InputValueDefinition{} = arg, types, schema) do
    type =
      Blueprint.TypeReference.unwrap(arg.type)
      |> Blueprint.TypeReference.to_type(schema)

    arg_type = Map.get(types, type)

    if arg_type && wrong_type?(Blueprint.Schema.InputValueDefinition, arg_type) do
      detail = %{
        argument: arg.identifier,
        type: arg_type.identifier,
        struct: arg_type.__struct__
      }

      arg |> put_error(error(arg.__reference__.location, detail))
    else
      arg
    end
  end

  defp validate_type(%struct{fields: fields} = type, types, schema) do
    fields =
      Enum.map(fields, fn
        %{type: _} = field ->
          type =
            Blueprint.TypeReference.unwrap(field.type)
            |> Blueprint.TypeReference.to_type(schema)

          field_type = Map.get(types, type)

          if field_type && wrong_type?(struct, field_type) do
            detail = %{
              field: field.identifier,
              type: field_type.identifier,
              struct: field_type.__struct__,
              parent: struct
            }

            field |> put_error(error(field.__reference__.location, detail))
          else
            field
          end

        field ->
          field
      end)

    %{type | fields: fields}
  end

  defp validate_type(type, _types, _schema) do
    type
  end

  @output_types [
    Blueprint.Schema.ObjectTypeDefinition,
    Blueprint.Schema.UnionTypeDefinition,
    Blueprint.Schema.InterfaceTypeDefinition
  ]
  defp wrong_type?(type, field_type) when type in @output_types do
    !output_type?(field_type)
  end

  @input_types [
    Blueprint.Schema.InputObjectTypeDefinition,
    Blueprint.Schema.InputValueDefinition
  ]
  defp wrong_type?(type, field_type) when type in @input_types do
    !input_type?(field_type)
  end

  defp error(location, data) do
    %Absinthe.Phase.Error{
      message: explanation(data),
      locations: [location],
      phase: __MODULE__,
      extra: data
    }
  end

  @moduledoc false

  @description """
  Only input types may be used as inputs. Input types may not be used as output types

  Input types consist of Scalars, Enums, and Input Objects.
  """

  def explanation(%{argument: argument, type: type, struct: struct}) do
    struct = struct |> Module.split() |> List.last()

    """
    #{inspect(type)} is not a valid input type for argument #{inspect(argument)} because
    #{inspect(type)} is an #{Macro.to_string(struct)}. Arguments may only be input types.

    #{@description}
    """
  end

  def explanation(%{field: field, type: type, struct: struct, parent: parent}) do
    struct = struct |> Module.split() |> List.last()
    parent = parent |> Module.split() |> List.last()

    """
    #{inspect(type)} is not a valid type for field #{inspect(field)} because
    #{inspect(type)} is an #{struct}, and this field is part of an #{parent}.

    #{@description}
    """
  end

  defp input_type?(%Blueprint.Schema.ScalarTypeDefinition{}), do: true
  defp input_type?(%Blueprint.Schema.EnumTypeDefinition{}), do: true
  defp input_type?(%Blueprint.Schema.InputObjectTypeDefinition{}), do: true
  defp input_type?(_), do: false

  defp output_type?(%Blueprint.Schema.InputObjectTypeDefinition{}), do: false
  defp output_type?(_), do: true
end
