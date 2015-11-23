defmodule ExGraphQL.Execution.Variables do

  alias ExGraphQL.Type
  alias ExGraphQL.Language

  @spec build(Type.Schema.t, [Language.VariableDefinition.t], %{binary => any}) :: %{binary => any}
  def build(schema, variable_definitions, provided_variables) do
    parsed = variable_definitions
    |> parse(schema, provided_variables, %{errors: %{}, values: %{}})
    case parsed do
      %{errors: errors, values: values} when map_size(errors) == 0 -> {:ok, values}
      %{errors: errors} -> {:error, errors}
    end
  end

  defp parse([], schema, provided_variables, acc) do
    acc
  end
  defp parse([definition|rest], schema, provided_variables, %{errors: errors, values: values} = acc) do
    variable_name = definition.variable.name
    variable_type = Type.Schema.type_from_ast(schema, definition.type)
    if variable_type do
      default_value = default(definition.default_value)
      provided_value = provided_variables[variable_name]
      value = provided_value || default_value
      if Type.valid_input?(variable_type, value) do
        coerced = if is_nil(value) do
          nil
        else
          variable_type
          |> Type.coerce(value)
        end
        parse(
          rest, schema, provided_variables,
          %{acc | values: values |> Map.put(variable_name, coerced)}
        )
      else
        err = if is_nil(value) do
          "can not be missing"
        else
          "invalid value: #{inspect value}"
        end
        parse(
          rest, schema, provided_variables,
          %{acc | errors: errors |> Map.put(variable_name, err)}
        )
      end
    else
      parse(
        rest, schema, provided_variables,
        %{acc | errors: errors |> Map.put(variable_name, "Could not determine type")}
      )
    end
  end

  @spec default(ExGraphQL.Language.value_t) :: any
  defp default(%{value: value}), do: value
  defp default(_), do: nil

end
