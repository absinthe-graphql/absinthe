defimpl ExGraphQL.Execution.Resolution, for: ExGraphQL.Language.Field do

  alias ExGraphQL.Execution
  alias ExGraphQL.Type
  alias ExGraphQL.Execution.ValueResolution

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
          |> result(ast_node, field, resolution, execution)
      end
    else
      {:skip, %{execution | errors: ["No field '#{ast_node.name}'"|errors]}}
    end
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
