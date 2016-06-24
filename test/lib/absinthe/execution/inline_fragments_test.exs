defmodule Absinthe.Execution.InlineFragmentsTest do
  use Absinthe.Case, async: true

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
    assert {:ok, %{data: %{"person" => %{"name" => "Bruce", "age" => 35}}}} == Absinthe.run(@query, ContactSchema)
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
          employee_count
        }
      }
    }
  }
  """

  it "adds fields in an interface query" do
    assert {:ok, %{data: %{"contact" => %{"entity" => %{"name" => "Bruce", "age" => 35}}}}} == Absinthe.run(@query, ContactSchema, variables: %{"business" => false})
    assert {:ok, %{data: %{"contact" => %{"entity" => %{"name" => "Someplace", "employeeCount" => 11}}}}} == Absinthe.run(@query, ContactSchema, variables: %{"business" => true})
  end

end
