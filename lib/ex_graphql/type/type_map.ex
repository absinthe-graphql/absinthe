defmodule ExGraphQL.Type.TypeMap do

  def build(%{query: query, mutation: mutation, subscription: subscription} = schema) do
    [query, mutation, subscription]
    |> Enum.reduce(%{}, &reducer/2)
  end

  # TODO: Built type map (see Ruby's GraphQL::Schema::TypeReducer)
  defp reducer(type, acc) do
    acc
  end

end
