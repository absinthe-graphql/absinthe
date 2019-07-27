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

        default_valid? =
          List.wrap(default_value)
          |> Enum.all?(fn default -> default in values end)

        if not default_valid? do
          detail = %{
            value_list: value_list,
            type: type,
            default_value: default_value
          }

          node |> put_error(error(node, detail))
        else
          node
        end

      _ ->
        node
    end
  end

  def validate_defaults(node, _) do
    node
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
