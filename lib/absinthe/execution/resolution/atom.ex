defimpl Absinthe.Execution.Resolution, for: Atom do

  @moduledoc """
  If we attempt to resolve at atom, we assume
  it is an identifier referencing a type.
  """

  alias Absinthe.Type
  alias Absinthe.Execution
  alias Absinthe.Execution.Resolution

  @spec resolve(Type.identifier_t, Execution.t) :: {:ok, map} | {:error, any}
  def resolve(identifier, %{schema: %{types_used: types_used}} = execution) do
    case types_used[identifier] do
      nil ->
        {:skip, execution}
      found_type ->
        Resolution.resolve(found_type, execution)
    end
  end
end
