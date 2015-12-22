defimpl Absinthe.Execution.Resolution, for: Absinthe.Type.List do

  alias Absinthe.Execution.Resolution

  def resolve(%{of_type: wrapped_type}, %{resolution: %{ast_node: %{selection_set: selection_set}, target: target}} = execution) do
    %{values: values_to_return, execution: execution_to_return} = target
    |> Enum.reduce(%{values: [], execution: execution}, fn (value_to_resolve, %{values: values_before, execution: current_execution}) ->
      this_resolution = %Resolution{type: wrapped_type, target: value_to_resolve}
      {:ok, result, next_execution} = Resolution.resolve(
        selection_set,
        %{current_execution | resolution: this_resolution}
      )
      %{values: [result|values_before], execution: next_execution}
    end)
    {:ok, values_to_return, execution_to_return}
  end

end
