defmodule Elixir.Absinthe.Integration.Execution.Introspection.SchemaTypesTest do
  use Absinthe.Case, async: true

  @query """
  query { __schema { types { name } } }
  """

  test "scenario #1" do
    result = Absinthe.run(@query, Absinthe.Fixtures.ContactSchema, [])
    assert {:ok, %{data: %{"__schema" => %{"types" => types}}}} = result
    names = types |> Enum.map(& &1["name"]) |> Enum.sort()

    expected =
      ~w(Int String Boolean Contact Person Business ProfileInput SearchResult NamedEntity RootMutationType RootQueryType RootSubscriptionType __Schema __Directive __DirectiveLocation __EnumValue __Field __InputValue __Type)
      |> Enum.sort()

    assert expected == names
  end
end
