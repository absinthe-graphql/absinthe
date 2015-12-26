defimpl Absinthe.Execution.Resolution, for: Atom do

  @moduledoc """
  If we attempt to resolve at atom, we assume
  it is an identifier referencing a type.
  """

  alias Absinthe.Schema
  alias Absinthe.Type
  alias Absinthe.Execution
  alias Absinthe.Execution.Resolution

  @spec resolve(Type.identifier_t, Execution.t) :: {:ok, map} | {:error, any}
  def resolve(identifier, execution) do
    case Schema.lookup_type(execution.schema, identifier) do
      nil ->
        {:skip, execution}
      found_type ->
        Resolution.resolve(found_type, execution)
    end
  end
end
