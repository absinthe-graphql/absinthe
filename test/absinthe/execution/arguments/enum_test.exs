defmodule Absinthe.Execution.Arguments.EnumTest do
  use Absinthe.Case, async: true

  @schema Absinthe.Fixtures.ArgumentsSchema

  @graphql """
  query {
    contact(type: "bagel")
  }
  """
  test "for invalid values, returns an error with" do
    assert_error_message(~s(Argument "type" has invalid value "bagel".), run(@graphql, @schema))
  end

  @graphql """
  query ($type: ContactType) {
    contact(type: $type)
  }
  """
  test "should pass nil as an argument to the resolver for enum types" do
    assert_data(%{"contact" => nil}, run(@graphql, @schema, variables: %{"type" => nil}))
  end

  @graphql """
  query {
    contact(type: Email)
  }
  """
  test "should work with valid values" do
    assert_data(%{"contact" => "Email"}, run(@graphql, @schema))
  end

  @graphql """
  query {
    contact(type: "bagel")
  }
  """
  test "should return an error with invalid values" do
    assert_error_message(~s(Argument "type" has invalid value "bagel".), run(@graphql, @schema))
  end

  @graphql """
  query ($type: ContactType){
    contact(type: $type)
  }
  """
  test "as variable, should work with valid values" do
    assert_data(%{"contact" => "Email"}, run(@graphql, @schema, variables: %{"type" => "Email"}))
  end
end
