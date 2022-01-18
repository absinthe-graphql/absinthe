defmodule Elixir.Absinthe.Integration.Validation.IntrospectionFieldsIgnoredInInputObjectsTest do
  use Absinthe.Case, async: true

  @query """
  mutation ($input: InputThing!) {
    thing: updateThing(id: "foo", thing: $input) {
      name
      value
    }
  }
  """

  test "scenario #1" do
    assert {:ok,
            %{
              errors: [
                %{
                  message:
                    "Argument \"thing\" has invalid value $input.\nIn field \"__typename\": Unknown field.",
                  locations: [%{column: 33, line: 2}]
                }
              ]
            }} ==
             Absinthe.run(
               @query,
               Absinthe.Fixtures.Things.MacroSchema,
               variables: %{"input" => %{"__typename" => "foo", "value" => 100}}
             )
  end
end
