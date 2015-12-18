defmodule ExGraphQL.Execution.Variables do

  alias ExGraphQL.Type
  alias ExGraphQL.Language
  alias ExGraphQL.Execution

  @spec build([Language.VariableDefinition.t], Execution.t) :: {%{binary => any}, Execution.t}
  def build(definitions, %{variables: variables} = execution) do
    definitions
    |> parse(execution, Execution.stringify_keys(variables))
  end

  defp parse(definitions, execution, provided) do
    do_parse(definitions, provided, {%{}, execution})
  end

  defp do_parse([] = _definitions, _provided, acc) do
    acc
  end
  defp do_parse([definition|rest], provided, {values, %{schema: schema} = execution}) do
    variable_name = definition.variable.name
    %{name: type_name} = unwrapped_definition_type = definition.type |> Language.unwrap
    variable_type = Type.Schema.type_from_ast(schema, definition.type)
    if variable_type do
      default_value = default(definition.default_value)
      provided_value = provided |> Map.get(variable_name |> to_string)
      value = provided_value || default_value
      if Type.valid_input?(variable_type, value) do
        coerced = if is_nil(value) do
          nil
        else
          type = variable_type |> Type.unwrap
          type.parse_value.(value)
        end
        do_parse(
          rest,
          provided,
          {
            values |> Map.put(variable_name, coerced),
            execution
          }
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
        do_parse(
          rest,
          provided,
          {
            values,
            %{execution | errors: [error | execution.errors]}
          }
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
        rest,
        provided,
        {
          values,
          %{execution | errors: [error | execution.errors]}
        }
      )
    end
  end

  @spec default(ExGraphQL.Language.value_t) :: any
  defp default(%{value: value}), do: value
  defp default(_), do: nil

end
