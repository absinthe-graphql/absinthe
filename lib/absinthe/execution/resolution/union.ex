defimpl Absinthe.Execution.Resolution, for: Absinthe.Type.Union do

  alias Absinthe.Execution.Resolution

  def resolve(union, %{resolution: %{ast_node: %{selection_set: selection_set}, target: target}} = execution) do
    deeper_resolution = %Resolution{type: union, target: target}
    Resolution.resolve(
      selection_set,
      %{execution | resolution: deeper_resolution}
    )
  end

end
