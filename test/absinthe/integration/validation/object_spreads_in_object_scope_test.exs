defmodule Elixir.Absinthe.Integration.Validation.ObjectSpreadsInObjectScopeTest do
  use Absinthe.Case, async: true

  @query """
  query Q {
    person {
      name
      ...NamedBusiness
    }
  }
  fragment NamedBusiness on Business {
    employee_count
  }
  """

  test "scenario #1" do
    assert {:ok,
            %{
              errors: [
                %{
                  message:
                    "Fragment spread has no type overlap with parent.\nParent possible types: [\"Person\"]\nSpread possible types: [\"Business\"]\n",
                  locations: [%{column: 5, line: 4}]
                }
              ]
            }} == Absinthe.run(@query, Absinthe.Fixtures.ContactSchema, [])
  end
end
