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

  it "spreads fragments with abstract target" do
    assert {:ok, %{data: %{"firstSearchResult" => %{"__typename" => "Person", "age" => 35}}}} == Absinthe.run(@query, ContactSchema)
  end

end
