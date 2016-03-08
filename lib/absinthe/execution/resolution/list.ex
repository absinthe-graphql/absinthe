defimpl Absinthe.Execution.Resolution, for: Absinthe.Type.List do

  alias Absinthe.Execution.Resolution

  def resolve(%{of_type: %{of_type: _} = wrapped_type}, execution) do
    # That's a list of list, we unwrap and pass it while keeping the selection_set
    do_resolve(wrapped_type, wrapped_type, execution)
  end
  def resolve(%{of_type: wrapped_type}, %{resolution: %{ast_node: %{selection_set: nil}}} = execution) do
    # There's no selection set, do inner resolution on the wrapped type
    do_resolve(wrapped_type, wrapped_type, execution)
  end
  def resolve(%{of_type: wrapped_type}, %{resolution: %{ast_node: %{selection_set: selection_set}}} = execution) do
    # There is a selection set, resolve the selection set
    do_resolve(wrapped_type, selection_set, execution)
  end

  def do_resolve(wrapped_type, inner_to_resolve, %{resolution: %{target: target}} = execution) do
    {values_to_return, execution_to_return} = Enum.reduce(target, {[], execution}, fn

      (value_to_resolve, {values_before, current_execution}) ->
        this_resolution = %Resolution{type: wrapped_type, target: value_to_resolve, ast_node: execution.resolution.ast_node}

        {:ok, result, next_execution} = Resolution.resolve(inner_to_resolve,
          %{current_execution | resolution: this_resolution}
        )

        {[result|values_before], next_execution}
    end)
    {:ok, Enum.reverse(values_to_return), execution_to_return}
  end

end
