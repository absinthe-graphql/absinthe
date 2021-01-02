defmodule Elixir.Absinthe.Integration.Execution.Introspection.TypeKindTest do
  use Absinthe.Case, async: true

  @query """
  query {
    __type(name: "__TypeKind") {
      name
      enumValues {
        name
      }
    }
  }
  """

  # https://spec.graphql.org/draft/#sel-HAJbLA6GABABKwzN
  #
  # enum __TypeKind {
  #   SCALAR
  #   OBJECT
  #   INTERFACE
  #   UNION
  #   ENUM
  #   INPUT_OBJECT
  #   LIST
  #   NON_NULL
  # }

  @expected [
    "SCALAR",
    "OBJECT",
    "INTERFACE",
    "UNION",
    "ENUM",
    "INPUT_OBJECT",
    "LIST",
    "NON_NULL"
  ]

  test "Contains expected values" do
    {:ok,
     %{
       data: %{
         "__type" => %{
           "name" => "__TypeKind",
           "enumValues" => enum_values
         }
       }
     }} = Absinthe.run(@query, Absinthe.Fixtures.ContactSchema, [])

    type_kind_values = enum_values |> Enum.map(& &1["name"])

    assert Enum.sort(type_kind_values) == Enum.sort(@expected)
  end
end
