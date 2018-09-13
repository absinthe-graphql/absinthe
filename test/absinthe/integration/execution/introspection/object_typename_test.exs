defmodule Elixir.Absinthe.Integration.Execution.Introspection.ObjectTypenameTest do
  use ExUnit.Case, async: true

  @query """
  query {
    person {
      __typename
      name
    }
  }
  """

  test "scenario #1" do
    assert {:ok, %{data: %{"person" => %{"__typename" => "Person", "name" => "Bruce"}}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.ContactSchema, [])
  end
end
