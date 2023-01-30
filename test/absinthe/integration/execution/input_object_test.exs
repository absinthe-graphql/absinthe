defmodule Elixir.Absinthe.Integration.Execution.InputObjectTest do
  use Absinthe.Case, async: true

  @query """
  mutation {
    updateThing(id: "foo", thing: {value: 100}) {
      name
      value
    }
  }
  """

  test "scenario #1" do
    assert {:ok, %{data: %{"updateThing" => %{"name" => "Foo", "value" => 100}}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema, [])
  end

  @query """
  mutation ($input: Boolean) {
    updateThing(id: "foo", thing: $input) {
      name
      value
    }
  }
  """

  test "errors if an invalid type is passed" do
    assert {:ok,
            %{
              errors: [
                %{
                  locations: [%{column: 26, line: 2}],
                  message: "Argument \"thing\" has invalid value $input."
                },
                %{
                  locations: [%{column: 33, line: 2}],
                  message:
                    "Variable `$input` of type `Boolean` found as input to argument of type `InputThing!`."
                }
              ]
            }} ==
             Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema,
               variables: %{"input" => true}
             )
  end
end
