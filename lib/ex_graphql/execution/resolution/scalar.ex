defimpl ExGraphQL.Execution.Resolution, for: ExGraphQL.Type.Scalar do

  def resolve(%{parse: parse}, %{resolution: %{target: target}} = execution) do
    case parse.(target) do
      {:ok, value} -> {:ok, value, execution}
      :error -> {:ok, nil, execution}
    end
  end

end
