defmodule Absinthe.Execution.Arguments.BooleanTest do
  use Absinthe.Case, async: true

  @schema Absinthe.Fixtures.ArgumentsSchema

  @graphql """
  query ($flag: Boolean!) {
    something(flag: $flag)
  }
  """

  test "variables are passed as arguments to resolution functions correctly" do
    assert_data(%{"something" => "YES"}, run(@graphql, @schema, variables: %{"flag" => true}))

    assert_data(%{"something" => "NO"}, run(@graphql, @schema, variables: %{"flag" => false}))
  end

  @graphql """
  query ($flag: Boolean) {
    something(flag: $flag)
  }
  """
  test "if a variable is not provided schema default value is used" do
    assert_data(%{"something" => "NO"}, run(@graphql, @schema))
  end

  test "literals are passed as arguments to resolution functions correctly" do
    assert_data(%{"something" => "YES"}, run(~s<query { something(flag: true) }>, @schema))

    assert_data(%{"something" => "NO"}, run(~s<query { something(flag: false) }>, @schema))

    assert_data(%{"something" => "NO"}, run(~s<query { something }>, @schema))
  end

  @graphql """
  query {
    something(flag: {foo: 1})
  }
  """
  test "returns a correct error when passed the wrong type" do
    assert_error_message_lines(
      [
        ~s(Argument "flag" has invalid value {foo: 1}.),
        ~s(In field \"foo\": Unknown field.)
      ],
      run(@graphql, @schema)
    )
  end
end
