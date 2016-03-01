defimpl Absinthe.Execution.Resolution, for: Atom do

  # If we attempt to resolve at atom, we assume
  # it is an identifier referencing a type.

  alias Absinthe.Schema
  alias Absinthe.Type
  alias Absinthe.Execution
  alias Absinthe.Execution.Resolution
  alias Absinthe.Flag

  @spec resolve(Type.identifier_t, Execution.t) :: {:ok, map} | {:error, any}
  def resolve(identifier, execution) do
    case Schema.lookup_type(execution.schema, identifier) do
      nil ->
        # This shouldn't normally occur since schema
        # verification should discover missing types.
        # The only case this should happen is if a bad __*
        # introspection type (not actually in the schema) is used.
        execution
        |> Execution.put_error(:type, identifier, "Not found in the schema", at: execution.resolution.ast_node)
        |> Flag.as(:skip)
      found_type ->
        Resolution.resolve(found_type, execution)
    end
  end
end
