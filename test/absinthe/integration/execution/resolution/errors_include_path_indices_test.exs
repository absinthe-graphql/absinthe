defmodule Elixir.Absinthe.Integration.Execution.Resolution.ErrorsIncludePathIndicesTest do
  use Absinthe.Case, async: true

  @query """
  query {
    things {
      id
      fail(id: "foo")
    }
  }
  """

  test "scenario #1" do
    assert {:ok,
            %{
              data: %{
                "things" => [%{"fail" => "bar", "id" => "bar"}, %{"fail" => nil, "id" => "foo"}]
              },
              errors: [
                %{
                  message: "fail",
                  path: ["things", 1, "fail"],
                  locations: [%{column: 5, line: 4}]
                }
              ]
            }} == Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema, [])
  end
end
