defmodule Absinthe.Phase.Document.Arguments.VariableTypesMatch do
  use Absinthe.Phase
  alias Absinthe.{Blueprint, Type}
  alias Absinthe.Blueprint.Input

  def run(bp, _) do
    bp =
      Blueprint.update_current(bp, fn op ->
        fragments = bp.fragments |> Map.new(&{&1.name, &1})
        check_variable_types(op, fragments)
      end)

    {:ok, bp}
  end

  def check_variable_types(op, fragments) do
    variable_defs = Map.new(op.variable_definitions, &{&1.name, &1})
    Blueprint.prewalk(op, &check_var_type(&1, variable_defs, fragments))
  end

  defp check_var_type(%{schema_node: nil} = node, _, _) do
    {:halt, node}
  end

  defp check_var_type(%Blueprint.Document.Fragment.Spread{name: name}, variables, fragments) do
    # TODO: handle this
    raise "not handled yet"
  end

  defp check_var_type(
         %Input.Value{raw: %{content: %Input.Variable{} = var}, schema_node: schema_node} = node,
         variable_defs
       ) do
    case Map.fetch(variable_defs, var.name) do
      {:ok, %{schema_node: var_schema_type}} when not is_nil(var_schema_type) ->
        # null vs not null is handled elsewhere
        var_schema_type = Type.unwrap(var_schema_type)
        arg_schema_type = Type.unwrap(schema_node)

        if var_schema_type.name != arg_schema_type.name do
          # error
          node
        else
          node
        end

      _ ->
        node
    end
  end

  defp check_var_type(node, _) do
    node
  end
end
