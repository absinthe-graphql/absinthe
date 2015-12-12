defimpl ExGraphQL.Execution.Resolution, for: ExGraphQL.Type.ObjectType do

  alias ExGraphQL.Execution.Resolution

  def resolve(object_type, %{ast_node: %{selection_set: selection_set}, target: target}, execution) do
    Resolution.resolve(
      selection_set,
      %Resolution{type: object_type, target: target},
      execution
    )
  end

end
