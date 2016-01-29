defimpl Absinthe.Execution.Resolution, for: Absinthe.Language.OperationDefinition do

  alias Absinthe.Execution.Resolution

  def resolve(operation, %{resolution: %{target: target}, root_value: root_value} = execution) do
    deeper_resolution = %Resolution{type: target, target: root_value}
    Resolution.resolve(
      operation.selection_set,
      %{execution | resolution: deeper_resolution}
    )
  end

end
