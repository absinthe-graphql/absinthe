defmodule Absinthe.Execution.Arguments.ScalarTest do
  use Absinthe.Case, async: true
  alias Absinthe.Blueprint.Input

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

  @graphql """
  query {
    raisingThing(name: {firstName: "bob"})
  }
  """
  test "invalid scalar does not call parse" do
    assert_error_message(
      "Argument \"name\" has invalid value {firstName: \"bob\"}.\nIn field \"firstName\": Unknown field.",
      run(@graphql, @schema)
    )
  end

  @graphql """
  query ($scalarVar: InputNameRaising) {
    raisingThing(name: $scalarVar)
  }
  """

  @valid_scalars %{
    Input.Boolean => true,
    Input.Float => 42.42,
    Input.Integer => 42,
    Input.String => "bob",
    Input.Null => nil
  }
  test "valid scalar does call parse" do
    for {expected_struct, value} <- @valid_scalars do
      assert_raise(
        RuntimeError,
        "inputNameRaising scalar parse was called for #{expected_struct}",
        fn ->
          run(@graphql, @schema, variables: %{"scalarVar" => value})
        end
      )
    end
  end
end
