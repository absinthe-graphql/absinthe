defimpl ExGraphQL.Execution.Resolution, for: ExGraphQL.Language.OperationDefinition do

  alias ExGraphQL.Execution.Resolution

  def resolve(operation, %{resolution: %{target: target}} = execution) do
    deeper_resolution = %Resolution{type: target}
    Resolution.resolve(
      operation.selection_set,
      %{execution | resolution: deeper_resolution}
    )
  end

end
