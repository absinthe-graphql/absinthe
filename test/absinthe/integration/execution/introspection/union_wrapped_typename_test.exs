defmodule Elixir.Absinthe.Integration.Execution.Introspection.UnionWrappedTypenameTest do
  use ExUnit.Case, async: true

  @query """
  query { searchResults { __typename } }
  """

  test "scenario #1" do
    assert {:ok,
            %{
              data: %{
                "searchResults" => [%{"__typename" => "Person"}, %{"__typename" => "Business"}]
              }
            }} == Absinthe.run(@query, Absinthe.Fixtures.ContactSchema, [])
  end
end
