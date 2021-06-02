defmodule Elixir.Absinthe.Integration.Execution.Aliases.WithErrorsTest do
  use Absinthe.Case, async: true

  @query """
  mutation { foo: failingThing(type: WITH_CODE) { name } }
  """

  test "scenario #1" do
    assert {:ok,
            %{
              data: %{"foo" => nil},
              errors: [
                %{
                  code: 42,
                  message: "Custom Error",
                  path: ["foo"],
                  locations: [%{column: 12, line: 1}]
                }
              ]
            }} == Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema, [])
  end

  @query """
  mutation {
    foo: failingThing(type: WITH_CODE) { name }
    bar: failingThing(type: WITH_CODE) { name }
  }
  """

  test "multiple aliases" do
    assert {
             :ok,
             %{
               data: %{"foo" => nil, "bar" => nil},
               errors: [
                 %{
                   code: 42,
                   locations: [%{column: 3, line: 3}],
                   message: "Custom Error",
                   path: ["bar"]
                 },
                 %{
                   code: 42,
                   locations: [%{column: 3, line: 2}],
                   message: "Custom Error",
                   path: ["foo"]
                 }
               ]
             }
           } == Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema, [])
  end
end
