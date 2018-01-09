defmodule Absinthe.Blueprint.Input.NullTest do
  @moduledoc """
  Tests basic use of null values.
  """

  use Absinthe.Case, async: true

  describe "as a literal, to a non-nullable argument" do

    @query """
    { times(base: null) }
    """
    test "if passed, adds an error" do
      assert_result {:ok, %{errors: [%{message: "Argument \"base\" has invalid value null."}]}}, run(@query, Absinthe.Fixtures.TimesSchema)
    end

  end

  describe "as a variable value, to a variable with a default value" do

    @query """
    query Test($mult: Int = 6) { times(base: 4, multiplier: $mult) }
    """
    test "if not passed, uses the default variable value" do
      assert_result {:ok, %{data: %{"times" => 24}}}, run(@query, Absinthe.Fixtures.TimesSchema)
    end

    @query """
    query Test($mult: Int = 6) { times(base: 4, multiplier: $mult) }
    """
    test "if passed, overrides the default and is passed as nil to the resolver" do
      assert_result {:ok, %{data: %{"times" => 4}}}, run(@query, Absinthe.Fixtures.TimesSchema, variables: %{"mult" => nil})
    end

  end

  describe "as a variable value, to a non-nullable variable" do

    @query """
    query Test($mult: Int!) { times(base: 4, multiplier: $mult) }
    """
    test "if passed, adds an error" do
      assert_result {:ok, %{errors: [%{message: "Variable \"mult\": Expected non-null, found null."}]}}, run(@query, Absinthe.Fixtures.TimesSchema, variables: %{"mult" => nil})
    end

  end

end
