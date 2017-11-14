defmodule Absinthe.Execution.OrderedInlineFragmentsTest do
  use Absinthe.Case, async: false, ordered: true
  use OrdMap

  @query """
  {
    person {
      name
      ... on Person {
        age
      }
    }
  }
  """

  it "adds fields in a simple case" do
    assert {:ok, %{data: o%{"person" => o%{"name" => "Bruce", "age" => 35}}}} == Absinthe.run(@query, ContactSchema)
  end

  @query """
  query Q($business: Boolean = false) {
    contact(business: $business) {
      entity {
        name
        ... on Person {
          age
        }
        ... on Business {
          employeeCount
        }
      }
    }
  }
  """

  it "adds fields in an interface query based on a type" do
    assert {:ok, %{data: o%{"contact" => o%{"entity" => o%{"name" => "Bruce", "age" => 35}}}}} == run(@query, ContactSchema, variables: %{"business" => false})
  end
  it "adds fields in an interface query based on another type" do
    assert {:ok, %{data: o%{"contact" => o%{"entity" => o%{"name" => "Someplace", "employeeCount" => 11}}}}} == run(@query, ContactSchema, variables: %{"business" => true})
  end

end
