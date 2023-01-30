defmodule Absinthe.Phase.Document.Arguments.VariableTypesMatch do
  @moduledoc false

  # Implements: 5.8.5. All Variable Usages are Allowed
  # Specifically, it implements "Variable usages must be compatible with the arguments they are passed to."
  # See relevant counter-example: https://spec.graphql.org/draft/#example-2028e

  use Absinthe.Phase

  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Document.{Operation, Fragment}
  alias Absinthe.Type

  def run(blueprint, _) do
    blueprint =
      blueprint
      |> check_operations()
      |> check_fragments()

    {:ok, blueprint}
  end

  def check_operations(%Blueprint{} = blueprint) do
    blueprint
    |> Map.update!(:operations, fn operations ->
      Enum.map(operations, &check_variable_types/1)
    end)
  end

  # A single fragment may be used by multiple operations.
  # Each operation may define its own variables.
  # This checks that each fragment is simultaneously consistent with the
  # variables defined in each of the operations which use that fragment.
  def check_fragments(%Blueprint{} = blueprint) do
    blueprint
    |> Map.update!(:fragments, fn fragments ->
      fragments
      |> Enum.map(fn fragment ->
        blueprint.operations
        |> Enum.filter(&Operation.uses?(&1, fragment))
        |> Enum.reduce(fragment, fn operation, fragment_acc ->
          check_variable_types(operation, fragment_acc)
        end)
      end)
    end)
  end

  def check_variable_types(%Operation{} = op) do
    variable_defs = Map.new(op.variable_definitions, &{&1.name, &1})
    Blueprint.prewalk(op, &check_variable_type(&1, op.name, variable_defs))
  end

  def check_variable_types(%Operation{} = op, %Fragment.Named{} = fragment) do
    variable_defs = Map.new(op.variable_definitions, &{&1.name, &1})
    Blueprint.prewalk(fragment, &check_variable_type(&1, op.name, variable_defs))
  end

  defp check_variable_type(%{schema_node: nil} = node, _, _) do
    {:halt, node}
  end

  defp check_variable_type(
         %Absinthe.Blueprint.Input.Argument{
           input_value: %Blueprint.Input.Value{
             raw: %{content: %Blueprint.Input.Variable{} = variable}
           }
         } = node,
         operation_name,
         variable_defs
       ) do
    location_type = node.input_value.schema_node
    location_definition = node.schema_node

    case Map.get(variable_defs, variable.name) do
      %{schema_node: variable_type} = variable_definition ->
        if types_compatible?(
             variable_type,
             location_type,
             variable_definition,
             location_definition
           ) do
          node
        else
          variable =
            put_error(
              variable,
              error(operation_name, variable, variable_definition, location_type)
            )

          {:halt, put_in(node.input_value.raw.content, variable)}
        end

      _ ->
        node
    end
  end

  defp check_variable_type(node, _, _) do
    node
  end

  def types_compatible?(type, type, _, _) do
    true
  end

  def types_compatible?(
        %Type.NonNull{of_type: nullable_variable_type},
        location_type,
        variable_definition,
        location_definition
      ) do
    types_compatible?(
      nullable_variable_type,
      location_type,
      variable_definition,
      location_definition
    )
  end

  def types_compatible?(
        %Type.List{of_type: item_variable_type},
        %Type.List{
          of_type: item_location_type
        },
        variable_definition,
        location_definition
      ) do
    types_compatible?(
      item_variable_type,
      item_location_type,
      variable_definition,
      location_definition
    )
  end

  # https://github.com/graphql/graphql-spec/blame/October2021/spec/Section%205%20--%20Validation.md#L1885-L1893
  # if argument has default value the variable can be nullable
  def types_compatible?(nullable_type, %Type.NonNull{of_type: nullable_type}, _, %{
        default_value: default_value
      })
      when not is_nil(default_value) do
    true
  end

  # https://github.com/graphql/graphql-spec/blame/main/spec/Section%205%20--%20Validation.md#L2000-L2005
  # This behavior is explicitly supported for compatibility with earlier editions of this specification.
  def types_compatible?(
        nullable_type,
        %Type.NonNull{of_type: nullable_type},
        %{
          default_value: value
        },
        _
      )
      when is_struct(value) do
    true
  end

  def types_compatible?(_, _, _, _) do
    false
  end

  defp error(operation_name, variable, variable_definition, location_type) do
    # need to rely on the type reference here, since the schema node may not be available
    # as the type could not exist in the schema
    variable_name = Absinthe.Blueprint.TypeReference.name(variable_definition.type)

    %Absinthe.Phase.Error{
      phase: __MODULE__,
      message:
        error_message(
          operation_name,
          variable,
          variable_name,
          Absinthe.Type.name(location_type)
        ),
      locations: [variable.source_location]
    }
  end

  def error_message(op, variable, variable_name, location_type) do
    start =
      case op || "" do
        "" -> "Variable"
        op -> "In operation `#{op}`, variable"
      end

    "#{start} `#{Blueprint.Input.inspect(variable)}` of type `#{variable_name}` found as input to argument of type `#{
      location_type
    }`."
  end
end
