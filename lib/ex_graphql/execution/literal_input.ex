defmodule ExGraphQL.Execution.LiteralInput do

  def from_arguments(ast_arguments, schema_arguments, variables) do
    schema_arguments
    |> Enum.reduce(%{}, fn ({name, definition}, acc) ->
      ast_arg = ast_arguments |> Enum.find(&(String.to_atom(&1.name) == String.to_atom(name)))
      if ast_arg do
        ast_value = if ast_arg.value do
          Type.coerce(definition.type, ast_arg.value)
        else
          nil
        end
        variable_value = variables[ast_arg.name]
        default_value = definition.default_value
        acc
        |> Map.put(ast_value || variable_value || default_value)
      else
        acc
      end
    end)
  end

end
