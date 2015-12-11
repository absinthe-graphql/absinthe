defimpl ExGraphQL.Execution.Resolution, for: ExGraphQL.Language.Field do

  alias ExGraphQL.Execution
  alias ExGraphQL.Type
  alias ExGraphQL.Execution.ValueResolution

  @spec resolve(ExGraphQL.Language.Field.t,
                ExGraphQL.Resolution.t,
                ExGraphQL.Execution.t) :: {:ok, map} | {:error, any}
  def resolve(ast_node, %{parent_type: parent_type} = resolution, %{schema: schema, variables: variables, strategy: :serial} = execution) do
    field = Type.field(parent_type, ast_node.name)
    arguments = Execution.LiteralInput.from_arguments(ast_node.arguments, field.args, variables)
    case field.resolve.(arguments, execution, resolution) do
      nil -> {:ok, nil, execution}
      value -> value |> result(ast_node, field, resolution, execution)
    end
  end

  defp result(value, ast_node, field, resolution, execution) do
    resolved_type = field.type.resolve_type.(value)
    resolved_value = ValueResolution.resolve(resolved_type, value, ast_node, resolution, execution)
    {:ok, resolved_value, execution}
  end

end
