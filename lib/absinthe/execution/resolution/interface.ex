defimpl Absinthe.Execution.Resolution, for: Absinthe.Type.Interface do

  alias Absinthe.Execution.Resolution

  def resolve(interface, %{resolution: %{ast_node: %{selection_set: selection_set}, target: target}} = execution) do
    deeper_resolution = %Resolution{type: interface, target: target}
    Resolution.resolve(
      selection_set,
      %{execution | resolution: deeper_resolution}
    )
  end

end
