defmodule Elixir.Absinthe.Integration.Execution.Introspection.InterfaceTypenameAliasTest do
  use Absinthe.Case, async: true

  @query """
  query { contact { entity { kind: __typename name } } }
  """

  test "scenario #1" do
    assert {:ok, %{data: %{"contact" => %{"entity" => %{"kind" => "Person", "name" => "Bruce"}}}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.ContactSchema, [])
  end
end
