defmodule Elixir.Absinthe.Integration.Execution.Introspection.SchemaTypesTest do
  use Absinthe.Case, async: true

  @query """
  query { __schema { types { name } } }
  """

  test "scenario #1" do
    result = Absinthe.run(@query, Absinthe.Fixtures.ContactSchema, [])
    assert {:ok, %{data: %{"__schema" => %{"types" => types}}}} = result
    names = types |> Enum.map(& &1["name"])

    # Core introspection types
    assert "__Directive" in names
    assert "__DirectiveLocation" in names
    assert "__EnumValue" in names
    assert "__Field" in names
    assert "__InputValue" in names
    assert "__Schema" in names
    assert "__Type" in names
    assert "__TypeKind" in names

    # TypeSystem directive introspection types
    assert "__AppliedDirective" in names
    assert "__DirectiveArgument" in names

    # ContactSchema types
    assert "Boolean" in names
    assert "Business" in names
    assert "Contact" in names
    assert "Int" in names
    assert "String" in names
    assert "Person" in names
    assert "ProfileInput" in names
    assert "RootQueryType" in names
    assert "RootMutationType" in names
    assert "RootSubscriptionType" in names
    assert "NamedEntity" in names
    assert "SearchResult" in names
  end
end
