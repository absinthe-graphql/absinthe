defmodule Absinthe.Phase.Schema.Validation.DefaultEnumValuePresent do
  use Absinthe.Phase
  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Schema

  def run(blueprint, _opts) do
    blueprint = Blueprint.prewalk(blueprint, &validate_schema/1)

    {:ok, blueprint}
  end

  def validate_schema(%Schema.SchemaDefinition{} = schema) do
    enums =
      schema.type_definitions
      |> Enum.filter(&match?(%Schema.EnumTypeDefinition{}, &1))
      |> Map.new(&{&1.identifier, &1})

    schema = Blueprint.prewalk(schema, &validate_defaults(&1, enums))
    {:halt, schema}
  end

  def validate_schema(node), do: node

  def validate_defaults(%{default_value: nil} = node, _) do
    node
  end

  def validate_defaults(%{default_value: default_value, type: type} = node, enums) do
    type = Blueprint.TypeReference.unwrap(type)

    case Map.fetch(enums, type) do
      {:ok, enum} ->
        values = Enum.map(enum.values, & &1.value)
        value_list = Enum.map(values, &"\n * #{inspect(&1)}")

        case value_conforms_to_enum(node.type, default_value, values) do
          {:error, value} ->
            detail = %{
              value_list: value_list,
              type: type,
              default_value: value
            }

            node |> put_error(error(node, detail))

          {:ok, _} ->
            node
        end

      _ ->
        node
    end
  end

  def validate_defaults(node, _) do
    node
  end

  defp value_conforms_to_enum(%Blueprint.TypeReference.List{of_type: of_type}, value, enum_values)
       when is_list(value) do
    value
    |> Enum.map(&value_conforms_to_enum(of_type, &1, enum_values))
    |> Enum.find({:ok, value}, &match?({:error, _}, &1))
  end

  defp value_conforms_to_enum(%_{of_type: of_type}, value, enum_values) do
    value_conforms_to_enum(of_type, value, enum_values)
  end

  defp value_conforms_to_enum(_, value, enum_values) do
    if value in enum_values do
      {:ok, value}
    else
      {:error, value}
    end
  end

  defp error(node, data) do
    %Absinthe.Phase.Error{
      message: explanation(data),
      locations: [node.__reference__.location],
      phase: __MODULE__,
      extra: data
    }
  end

  @moduledoc false

  def explanation(%{default_value: default_value, type: type, value_list: value_list}) do
    """
    The default_value for an enum must be present in the enum values.

    Could not use default value of `#{inspect(default_value)}` for #{inspect(type)}.

    Valid values are:
    #{value_list}
    """
  end
end
