defmodule ExGraphQL.Execution.Variables do

  alias ExGraphQL.Type
  alias ExGraphQL.Language
  alias ExGraphQL.Execution
  alias ExGraphQL.Execution.LiteralInput

  @spec build(Type.Schema.t, [Language.VariableDefinition.t], %{binary => any}) :: %{binary => any}
  def build(schema, variable_definitions, provided_variables) do
    parsed = variable_definitions
    |> parse(schema, provided_variables |> Execution.stringify_keys, %{errors: [], values: %{}})
  end

  defp parse([], schema, provided_variables, acc) do
    acc
  end
  defp parse([definition|rest], schema, provided_variables, %{errors: errors, values: values} = acc) do
    variable_name = definition.variable.name
    %{name: type_name} = unwrapped_definition_type = definition.type |> Language.unwrap
    variable_type = Type.Schema.type_from_ast(schema, definition.type)
    if variable_type do
      default_value = default(definition.default_value)
      provided_value = provided_variables[variable_name]
      value = provided_value || default_value
      if Type.valid_input?(variable_type, value) do
        coerced = if is_nil(value) do
          nil
        else
          with type <- variable_type |> Type.unwrap do
            type.parse_value.(value)
          end
        end
        parse(
          rest, schema, provided_variables,
          %{acc | values: values |> Map.put(variable_name, coerced)}
        )
      else
        err = if is_nil(value) do
          "Missing required variable '#{variable_name}' (#{type_name})"
        else
          "Invalid value for variable '#{variable_name}' (#{type_name}): #{inspect value}"
        end
        error = Execution.format_error(err, unwrapped_definition_type)
        parse(
          rest, schema, provided_variables,
          %{acc | errors: [error|errors]}
        )
      end
    else
      error = Execution.format_error("Could not find type '#{type_name}' in schema", unwrapped_definition_type)
      parse(
        rest, schema, provided_variables,
        %{acc | errors: [error|errors]}
      )
    end
  end

  @spec default(ExGraphQL.Language.value_t) :: any
  defp default(%{value: value}), do: value
  defp default(_), do: nil

end
