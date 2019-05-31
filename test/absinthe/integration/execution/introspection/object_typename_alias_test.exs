defmodule Elixir.Absinthe.Integration.Execution.Introspection.ObjectTypenameAliasTest do
  use Absinthe.Case, async: true

  @query """
  query {
    person {
      kind: __typename
      name
    }
  }
  """

  test "scenario #1" do
    assert {:ok, %{data: %{"person" => %{"kind" => "Person", "name" => "Bruce"}}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.ContactSchema, [])
  end
end
