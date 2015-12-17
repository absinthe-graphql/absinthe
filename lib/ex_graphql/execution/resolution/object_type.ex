defimpl ExGraphQL.Execution.Resolution, for: ExGraphQL.Type.ObjectType do

  alias ExGraphQL.Execution.Resolution

  def resolve(object_type, %{resolution: %{ast_node: %{selection_set: selection_set}, target: target}} = execution) do
    deeper_resolution = %Resolution{type: object_type, target: target}
    Resolution.resolve(
      selection_set,
      %{execution | resolution: deeper_resolution}
    )
  end

end
