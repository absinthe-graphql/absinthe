defimpl ExGraphQL.Execution.Resolution, for: ExGraphQL.Type.Scalar do

  def resolve(%{serialize: serialize}, %{resolution: %{target: target}} = execution) do
    {:ok, serialize.(target), execution}
  end

end
