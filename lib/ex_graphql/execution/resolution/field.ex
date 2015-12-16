defimpl ExGraphQL.Execution.Resolution, for: ExGraphQL.Language.Field do

  alias ExGraphQL.Execution
  alias ExGraphQL.Type

  @spec resolve(ExGraphQL.Language.Field.t,
                ExGraphQL.Resolution.t,
                ExGraphQL.Execution.t) :: {:ok, map} | {:error, any}
  def resolve(%{name: name} = ast_node, %{parent_type: parent_type, target: target} = resolution, %{schema: schema, errors: errors, variables: variables, strategy: :serial} = execution) do
    field = Type.field(parent_type, ast_node.name)
    if field do
      arguments = Execution.LiteralInput.from_arguments(ast_node.arguments, field.args, variables)
      case field do
        %{resolve: nil} ->
          target |> Map.get(name |> String.to_atom) |> result(ast_node, field, resolution, execution)
        %{resolve: resolver} ->
          field.resolve.(arguments, execution, resolution)
          |> process_raw_result(ast_node, field, resolution, execution)
      end
    else
      {:skip, %{execution | errors: [Execution.format_error("No field '#{ast_node.name}'", ast_node)|errors]}}
    end
  end

  defp process_raw_result({:ok, value}, ast_node, field, resolution, execution) do
    value
    |> result(ast_node, field, resolution, execution)
  end
  defp process_raw_result({:error, error}, ast_node, _field, _resolution, execution) do
    new_errors = error |> List.wrap |> Enum.map(&(Execution.format_error(&1, ast_node)))
    {:skip, %{execution | errors: new_errors ++ execution.errors }}
  end
  defp process_raw_result(_other, ast_node, _field, _resolution, execution) do
    error = "Schema did not resolve '#{ast_node.name}' to match {:ok, _} or {:error, _}" |> Execution.format_error(ast_node)
    {:skip, %{execution | errors: [error|execution.errors]}}
  end

  defp result(nil, _ast_node, _field, _resolution, execution) do
    {:ok, nil, execution}
  end
  defp result(value, ast_node, field, resolution, execution) do
    resolved_type = Type.resolve_type(field.type, value)
    Execution.Resolution.resolve(
      resolved_type,
      %Execution.Resolution{type: resolved_type, ast_node: ast_node, target: value},
      execution
    )
  end

end
