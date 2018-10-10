defmodule Elixir.Absinthe.Integration.Execution.Introspection.InterfaceTypenameTest do
  use ExUnit.Case, async: true

  @query """
  query { contact { entity { __typename name } } }
  """

  test "scenario #1" do
    assert {:ok,
            %{data: %{"contact" => %{"entity" => %{"__typename" => "Person", "name" => "Bruce"}}}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.ContactSchema, [])
  end
end
