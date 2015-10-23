defmodule ExGraphQL.Type.Schema do
  defstruct query: nil, mutation: nil, type_map: %{}

  use ExGraphQL.Type.Creation
  def setup(struct) do
    # TODO: Should also introspect struct, see graphql-js' `__Struct`
    types_to_map = [struct.query, struct.mutation]
    case types_to_map |> &ExGraphQL.Type.TypeMap.build(%{}) do
      {:ok, type_map} -> {:ok, %{struct | type_map: type_map}}
      {:error, _} = err -> err
    end
  end

end
