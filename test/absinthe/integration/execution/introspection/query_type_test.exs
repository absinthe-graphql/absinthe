defmodule Elixir.Absinthe.Integration.Execution.Introspection.QueryTypeTest do
  use Absinthe.Case, async: true

  @query """
  query { __schema { queryType { name kind } } }
  """

  test "scenario #1" do
    assert {:ok,
            %{
              data: %{
                "__schema" => %{"queryType" => %{"kind" => "OBJECT", "name" => "RootQueryType"}}
              }
            }} == Absinthe.run(@query, Absinthe.Fixtures.ContactSchema, [])
  end
end
