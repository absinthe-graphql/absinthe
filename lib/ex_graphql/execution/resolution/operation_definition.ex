defimpl ExGraphQL.Execution.Resolution, for: ExGraphQL.Language.OperationDefinition do

  alias ExGraphQL.Execution.Resolution

  def resolve(operation, resolution, execution) do
    Resolution.resolve(
      operation.selection_set,
      %Resolution{type: resolution.target},
      execution
    )
  end

end
