defmodule Absinthe.Phase.Document.Arguments.VariableTypesMatch do
  # Partially implements: 5.8.5. All Variable Usages are Allowed
  # Specifically, it implements "Variable usages must be compatible with the arguments they are passed to."
  # See relevant counter-example: https://spec.graphql.org/draft/#example-2028e

  use Absinthe.Phase

  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Document.{Operation, Fragment}

  def run(blueprint, _) do
    blueprint =
      blueprint
      |> check_operations()
      |> check_fragments()

    {:ok, blueprint}
  end

  def check_operations(%Blueprint{} = blueprint) do
    blueprint.operations
    |> Enum.reduce(blueprint, fn operation, blueprint ->
      update_operation(blueprint, operation, &check_variable_types/1)
    end)
  end

  def check_fragments(%Blueprint{} = blueprint) do
    blueprint.fragments
    |> Enum.reduce(blueprint, fn fragment, blueprint ->
      blueprint.operations
      |> Enum.filter(&Operation.uses?(&1, fragment))
      |> Enum.reduce(blueprint, fn operation, blueprint ->
        update_fragment(blueprint, fragment, &check_variable_types(operation, &1))
      end)
    end)
  end

  defp update_operation(%Blueprint{} = blueprint, %Operation{name: name} = operation, fun) do
    operations =
      blueprint.operations
      |> Enum.map(fn
        # operations are unique by name
        %{name: ^name} -> fun.(operation)
        other -> other
      end)

    %{blueprint | operations: operations}
  end

  defp update_fragment(%Blueprint{} = blueprint, %Fragment.Named{name: name} = fragment, fun) do
    fragments =
      blueprint.fragments
      |> Enum.map(fn
        # named_fragments are unique by name
        %{name: ^name} -> fun.(fragment)
        other -> other
      end)

    %{blueprint | fragments: fragments}
  end

  def check_variable_types(%Operation{} = op) do
    variable_defs = Map.new(op.variable_definitions, &{&1.name, &1})
    Blueprint.prewalk(op, &check_var_type(&1, op, variable_defs))
  end

  def check_variable_types(%Operation{} = op, %Fragment.Named{} = fragment) do
    variable_defs = Map.new(op.variable_definitions, &{&1.name, &1})
    Blueprint.prewalk(fragment, &check_var_type(&1, op, variable_defs))
  end

  defp check_var_type(%{schema_node: nil} = node, _, _) do
    {:halt, node}
  end

  defp check_var_type(
         %Blueprint.Input.Value{
           raw: %{content: %Blueprint.Input.Variable{} = var},
           schema_node: schema_node
         } = node,
         %Operation{} = op,
         variable_defs
       ) do
    case Map.fetch(variable_defs, var.name) do
      {:ok, %{schema_node: var_schema_type}} when not is_nil(var_schema_type) ->
        # null vs not null is handled elsewhere
        var_schema_type = Absinthe.Type.unwrap(var_schema_type)
        arg_schema_type = Absinthe.Type.unwrap(schema_node)

        if var_schema_type.name != arg_schema_type.name do
          # error
          var_with_error =
            put_error(var, %Absinthe.Phase.Error{
              phase: __MODULE__,
              message:
                error_message(op.name, var.name, var_schema_type.name, arg_schema_type.name),
              locations: [var.source_location]
            })

          {:halt, put_in(node.raw.content, var_with_error)}
        else
          node
        end

      _ ->
        node
    end
  end

  defp check_var_type(node, _, _) do
    node
  end

  def error_message(op, var_name, var_type, arg_type) do
    "In operation `#{op}`, variable `#{var_name}` of type `#{var_type}` found as input to argument of type `#{
      arg_type
    }`."
  end
end
