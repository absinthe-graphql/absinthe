defmodule Elixir.Absinthe.Integration.Execution.Introspection.SchemaTypesTest do
  use Absinthe.Case, async: true

  @query """
  query { __schema { types { name } } }
  """

  @expected [
    "__Directive",
    "__DirectiveLocation",
    "__EnumValue",
    "__Field",
    "__InputValue",
    "__Schema",
    "__Type",
    "__TypeKind",
    "Boolean",
    "Business",
    "Contact",
    "Int",
    "RootMutationType",
    "NamedEntity",
    "Person",
    "ProfileInput",
    "RootQueryType",
    "SearchResult",
    "String",
    "RootSubscriptionType"
  ]

  test "scenario #1" do
    result = Absinthe.run(@query, Absinthe.Fixtures.ContactSchema, [])
    assert {:ok, %{data: %{"__schema" => %{"types" => types}}}} = result
    names = types |> Enum.map(& &1["name"])

    assert @expected == names
  end
end
