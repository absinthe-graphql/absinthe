defmodule Elixir.Absinthe.Integration.Execution.Introspection.MutationTypeTest do
  use Absinthe.Case, async: true

  @query """
  query { __schema { mutationType { name kind } } }
  """

  test "scenario #1" do
    assert {:ok,
            %{
              data: %{
                "__schema" => %{
                  "mutationType" => %{"kind" => "OBJECT", "name" => "Mutation"}
                }
              }
            }} == Absinthe.run(@query, Absinthe.Fixtures.ContactSchema, [])
  end
end
