defmodule Absinthe.Execution.Arguments.ScalarTest do
  use Absinthe.Case, async: true

  @schema Absinthe.Fixtures.ArgumentsSchema

  @graphql """
  query {
    requiredThing(name: "bob")
  }
  """
  test "works when specified as non null" do
    assert_data(%{"requiredThing" => "bob"}, run(@graphql, @schema))
  end

  @graphql """
  query {
    something(name: "bob")
  }
  """
  test "works when passed to resolution" do
    assert_data(%{"something" => "bob"}, run(@graphql, @schema))
  end
end
