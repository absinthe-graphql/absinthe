defmodule Absinthe.Execution.OrderedFragmentSpreadTest do
  use Absinthe.Case, async: false, ordered: true
  use OrdMap

  @query """
  query AbstractFragmentSpread {
    firstSearchResult {
      ...F0
    }
  }

  fragment F0 on SearchResult {
    __typename
    ...F1
  }

  fragment F1 on Person {
    age
  }
  """

  it "spreads fragments with abstract target" do
    assert {:ok, %{data: o%{"firstSearchResult" => o%{"__typename" => "Person", "age" => 35}}}} == Absinthe.run(@query, ContactSchema)
  end

  it "spreads errors fragments that don't refer to a real type" do
    query = """
    query {
      __typename
    }
    fragment F0 on Foo {
      name
    }
    """
    assert {:ok, %{errors: [%{locations: [%{column: 0, line: 4}], message: "Unknown type \"Foo\"."}]}} == Absinthe.run(query, ContactSchema)
  end

  it "errors properly when spreading fragments that don't exist" do
    query = """
    query {
      __typename
      ... NonExistentFragment
    }
    """
    assert {:ok, %{errors: [%{locations: [%{column: 0, line: 3}], message: "Unknown fragment \"NonExistentFragment\""}]}} == Absinthe.run(query, ContactSchema)
  end

end
