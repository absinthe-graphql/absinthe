defmodule Elixir.Absinthe.Integration.Execution.Fragments.BasicTest do
  use Absinthe.Case, async: true

  @query """
  query Q {
    person {
      ...NamedPerson
    }
  }
  fragment NamedPerson on Person {
    name
  }
  """

  test "scenario #1" do
    assert {:ok, %{data: %{"person" => %{"name" => "Bruce"}}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.ContactSchema, [])
  end
end
