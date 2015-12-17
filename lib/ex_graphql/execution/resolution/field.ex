defimpl ExGraphQL.Execution.Resolution, for: ExGraphQL.Language.Field do

  alias ExGraphQL.Execution
  alias ExGraphQL.Execution.Resolution
  alias ExGraphQL.Type

  @spec resolve(ExGraphQL.Language.Field.t,
                ExGraphQL.Execution.t) :: {:ok, map} | {:error, any}
  def resolve(%{name: name} = ast_node, %{errors: errors, variables: variables, strategy: :serial, resolution: %{parent_type: parent_type, target: target}} = execution) do
    field = Type.field(parent_type, ast_node.name)
    if field do
      arguments = Execution.Arguments.build(ast_node.arguments, field.args, variables)
      case field do
        %{resolve: nil} ->
          target |> Map.get(name |> String.to_atom) |> result(ast_node, field, execution)
        %{resolve: resolver} ->
          resolver.(arguments, execution)
          |> process_raw_result(ast_node, field, execution)
      end
    else
      error_info = %{name: ast_node.name, role: :field, value: "Not present in schema"}
      error = Execution.format_error(execution, error_info, ast_node)
      {:skip, %{execution | errors: [error|errors]}}
    end
  end

  defp process_raw_result({:ok, value}, ast_node, field, execution) do
    value
    |> result(ast_node, field, execution)
  end
  defp process_raw_result({:error, error}, ast_node, _field, execution) do
    new_errors = error
    |> List.wrap
    |> Enum.map(fn (value) ->
      error_info = %{name: ast_node.name, role: :field, value: value}
      Execution.format_error(execution, error_info, ast_node)
    end)
    {:skip, %{execution | errors: new_errors ++ execution.errors }}
  end
  defp process_raw_result(_other, ast_node, _field, execution) do
    error_info = %{
      name: ast_node.name,
      role: :field,
      value: "Did not resolve to match {:ok, _} or {:error, _}"
    }
    error = Execution.format_error(execution, error_info, ast_node)
    {:skip, %{execution | errors: [error|execution.errors]}}
  end

  defp result(nil, _ast_node, _field, execution) do
    {:ok, nil, execution}
  end
  defp result(value, ast_node, field, execution) do
    resolved_type = Type.resolve_type(field.type, value)
    next_resolution = %Resolution{type: resolved_type, ast_node: ast_node, target: value}
    Resolution.resolve(resolved_type, %{execution | resolution: next_resolution})
  end

end
