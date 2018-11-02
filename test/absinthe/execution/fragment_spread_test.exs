defmodule Absinthe.Execution.FragmentSpreadTest do
  use Absinthe.Case, async: true

  @query """
  query AbstractFragmentSpread {
    firstSearchResult {
      ...F0
    }
  }

  fragment F0 on SearchResult {
    ...F1
    __typename
  }

  fragment F1 on Person {
    age
  }
  """

  test "spreads fragments with abstract target" do
    assert {:ok, %{data: %{"firstSearchResult" => %{"__typename" => "Person", "age" => 35}}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.ContactSchema)
  end

  test "spreads errors fragments that don't refer to a real type" do
    query = """
    query {
      __typename
    }
    fragment F0 on Foo {
      name
    }
    """

    assert {:ok,
            %{
              errors: [
                %{locations: [%{column: 1, line: 4}], message: "Unknown type \"Foo\"."},
                %{locations: [%{column: 1, line: 4}], message: "Fragment \"F0\" is never used."}
              ]
            }} == Absinthe.run(query, Absinthe.Fixtures.ContactSchema)
  end

  test "errors properly when spreading fragments that don't exist" do
    query = """
    query {
      __typename
      ... NonExistentFragment
    }
    """

    assert {:ok,
            %{
              errors: [
                %{
                  locations: [%{column: 3, line: 3}],
                  message: "Unknown fragment \"NonExistentFragment\""
                }
              ]
            }} == Absinthe.run(query, Absinthe.Fixtures.ContactSchema)
  end
end
