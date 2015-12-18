defmodule ExGraphQL.Execution.Variables do

  alias ExGraphQL.Type
  alias ExGraphQL.Language
  alias ExGraphQL.Execution

  @spec build(Execution.t, [Language.VariableDefinition.t], %{binary => any}) :: %{values: %{binary => any}, errors: [Execution.error_t]}
  def build(execution, variable_definitions, provided_variables) do
    variable_definitions
    |> parse(execution, provided_variables |> Execution.stringify_keys, %{errors: [], values: %{}})
  end

  defp parse([], _execution, _provided_variables, acc) do
    acc
  end
  defp parse([definition|rest], %{schema: schema} = execution, provided_variables, %{errors: errors, values: values} = acc) do
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
          type = variable_type |> Type.unwrap
          type.parse_value.(value)
        end
        parse(
          rest, execution, provided_variables,
          %{acc | values: values |> Map.put(variable_name, coerced)}
        )
      else
        err = if is_nil(value) do
          &"Variable `#{&1}' (#{type_name}): Not provided"
        else
          &"Variable `#{&1}' (#{type_name}): Invalid value"
        end
        error_info = %{
          name: variable_name,
          role: :variable,
          value: err
        }
        error = Execution.format_error(execution, error_info, unwrapped_definition_type)
        parse(
          rest, execution, provided_variables,
          %{acc | errors: [error|errors]}
        )
      end
    else
      error_info = %{
        name: variable_name,
        role: :variable,
        value: "Type (#{type_name}) not present in schema"
      }
      error = Execution.format_error(execution, error_info, unwrapped_definition_type)
      parse(
        rest, execution, provided_variables,
        %{acc | errors: [error|errors]}
      )
    end
  end

  @spec default(ExGraphQL.Language.value_t) :: any
  defp default(%{value: value}), do: value
  defp default(_), do: nil

end
