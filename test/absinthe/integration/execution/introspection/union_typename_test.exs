defmodule Elixir.Absinthe.Integration.Execution.Introspection.UnionTypenameTest do
  use Absinthe.Case, async: true

  @query """
  query { firstSearchResult { __typename } }
  """

  test "scenario #1" do
    assert {:ok, %{data: %{"firstSearchResult" => %{"__typename" => "Person"}}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.ContactSchema, [])
  end
end
