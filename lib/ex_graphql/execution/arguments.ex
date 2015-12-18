defmodule ExGraphQL.Execution.Arguments do

  alias ExGraphQL.Language
  alias ExGraphQL.Execution.Literal

  @spec build([Language.Argument.t], [Type.Argument.t], Execution.t) :: {%{atom => any}, Execution.t}
  def build(ast_arguments, schema_arguments, %{variables: variables} = execution) do
    result = {%{}, execution}
    schema_arguments
    |> Enum.reduce(result, fn ({name, definition}, {values, exe} = acc) ->
      schema_arg_name = name |> to_string
      ast_arg = ast_arguments |> Enum.find(&(&1.name == schema_arg_name))
      if ast_arg do
        ast_value = if ast_arg.value do
          Literal.coerce(definition.type, ast_arg.value, variables)
        else
          nil
        end
        variable_value = variables[ast_arg.name]
        default_value = definition.default_value
        {
          values |> Map.put(name, ast_value || variable_value || default_value),
          exe
        }
      else
        acc
      end
    end)
  end

end
