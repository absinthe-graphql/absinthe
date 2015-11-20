defmodule ExGraphQL.Type.Schema do
  @type t :: %{query:        ExGraphQL.Type.ObjectType.t | nil,
               mutation:     ExGraphQL.Type.ObjectType.t | nil,
               subscription: ExGraphQL.Type.ObjectType.t | nil,
               type_map:     map}
  defstruct query: nil, mutation: nil, subscription: nil, type_map: %{}

  @spec type_map(t) :: ExGraphQL.Type.TypeMap.t
  @doc "Get the type map for a schema"
  def type_map(%{query: query, mutation: mutation, subscription: subscription}) do
    case [query, mutation, subscription] |> ExGraphQL.Type.TypeMap.build do
      {:ok, type_map} -> {:ok, type_map}
      {:error, _} = err -> err
    end
  end

end
