defimpl Absinthe.Execution.Resolution, for: Absinthe.Type.Enum do

  def resolve(enum, %{resolution: %{target: target}} = execution) do
    {:ok, Absinthe.Type.Enum.serialize!(enum, target), execution}
  end

end
