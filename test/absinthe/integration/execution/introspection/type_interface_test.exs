defmodule Elixir.Absinthe.Integration.Execution.Introspection.TypeInterfaceTest do
  use Absinthe.Case, async: true

  @query """
  query {
    __type(name: "NamedEntity") {
      kind
      name
      description
      possibleTypes {
        name
      }
    }
  }
  """

  test "scenario #1" do
    assert {:ok,
            %{
              data: %{
                "__type" => %{
                  "description" => "A named entity",
                  "kind" => "INTERFACE",
                  "name" => "NamedEntity",
                  "possibleTypes" => [%{"name" => "Business"}, %{"name" => "Person"}]
                }
              }
            }} == Absinthe.run(@query, Absinthe.Fixtures.ContactSchema, [])
  end
end
