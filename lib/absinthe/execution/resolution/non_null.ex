defimpl Absinthe.Execution.Resolution, for: Absinthe.Type.NonNull do

  alias Absinthe.Execution.Resolution

  def resolve(%{of_type: wrapped_type}, execution) do
    Resolution.resolve(wrapped_type, execution)
  end

end
