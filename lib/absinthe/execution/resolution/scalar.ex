defimpl Absinthe.Execution.Resolution, for: Absinthe.Type.Scalar do

  def resolve(%{serialize: serialize}, %{resolution: %{target: target}} = execution) do
    {:ok, serialize.(target), execution}
  end

end
