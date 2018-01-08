defmodule Absinthe.Blueprint.Input.Null.WithinListTest do
  @moduledoc """
  Tests use of null values within lists.
  """

  use Absinthe.Case, async: true


  describe "as a variable, to an [Int]" do

    @query """
    query ($value: [Int]) {
      nullableList(input: $value) {
        length
        content
        nonNullCount
        nullCount
      }
    }
    """
    test "if passed as a value, is treated as a null argument" do
      assert_result {
        :ok,
        %{
          data: %{
            "nullableList" => nil
          }
        }
      }, run(@query, Absinthe.Fixtures.NullListsSchema, variables: %{"value" => nil})
    end

    @query """
    query ($value: [Int] ){
      nullableList(input: $value) {
        length
        content
        nonNullCount
        nullCount
      }
    }
    """
    test "if passed as an element, is treated as a valid value" do
      assert_result {
        :ok,
        %{
          data: %{
            "nullableList" => %{
              "length" => 2,
              "content" => [nil, 1],
              "nullCount" => 1,
              "nonNullCount" => 1
            }
          }
        }
      }, run(@query, Absinthe.Fixtures.NullListsSchema, variables: %{"value" => [nil, 1]})
    end
  end

  describe "as a variable, to an [Int]!" do

    @query """
    query ($value: [Int]!) {
      nonNullableList(input: $value) {
        length
        content
        nonNullCount
        nullCount
      }
    }
    """
    test "if passed as a value, is treated as a null argument" do
      assert_result {
        :ok,
        %{
          errors: [%{message: "Argument \"input\" has invalid value $value."}, %{message: "Variable \"value\": Expected non-null, found null."}]
        }
      }, run(@query, Absinthe.Fixtures.NullListsSchema, variables: %{"value" => nil})
    end

    @query """
    query ($value: [Int]!){
      nonNullableList(input: $value) {
        length
        content
        nonNullCount
        nullCount
      }
    }
    """
    test "if passed as an element, is treated as a valid value" do
      assert_result {
        :ok,
        %{
          data: %{
            "nonNullableList" => %{
              "length" => 2,
              "content" => [nil, 1],
              "nullCount" => 1,
              "nonNullCount" => 1
            }
          }
        }
      }, run(@query, Absinthe.Fixtures.NullListsSchema, variables: %{"value" => [nil, 1]})
    end

  end

  describe "as a variable, to an [Int!]" do

    @query """
    query ($value: [Int!]) {
      nullableListOfNonNullableType(input: $value) {
        length
        content
        nonNullCount
        nullCount
      }
    }
    """
    test "if passed as a value, is treated as a null argument" do
      assert_result {
        :ok,
        %{
          data: %{
            "nullableListOfNonNullableType" => nil
          }
        }
      }, run(@query, Absinthe.Fixtures.NullListsSchema, variables: %{"value" => nil})
    end

    @query """
    query ($value: [Int!]){
      nullableListOfNonNullableType(input: $value) {
        length
        content
        nonNullCount
        nullCount
      }
    }
    """
    test "if passed as an element, returns an error" do
      assert_result {
        :ok,
        %{
          errors: [
            %{message: "Argument \"input\" has invalid value $value.\nIn element #1: Expected type \"Int!\", found null."}
          ]
        }
      }, run(@query, Absinthe.Fixtures.NullListsSchema, variables: %{"value" => [nil, 1]})
    end

  end

  describe "as a variable, to an [Int!]!" do

    @query """
    query ($value: [Int!]!){
      nonNullableListOfNonNullableType(input: $value) {
        length
        content
        nonNullCount
        nullCount
      }
    }
    """
    test "if passed as the value, is treated as a null argument" do
      assert_result {
        :ok,
        %{
          errors: [%{message: "Argument \"input\" has invalid value $value."}, %{message: "Variable \"value\": Expected non-null, found null."}]
        }
      }, run(@query, Absinthe.Fixtures.NullListsSchema, variables: %{"value" => nil})
    end

    @query """
    query ($value: [Int!]!) {
      nonNullableListOfNonNullableType(input: $value) {
        length
        content
        nonNullCount
        nullCount
      }
    }
    """
    test "if passed as an element, returns an error" do
      assert_result {
        :ok,
        %{
          errors: [
            %{message: "Argument \"input\" has invalid value $value.\nIn element #1: Expected type \"Int!\", found null."}
          ]
        }
      }, run(@query, Absinthe.Fixtures.NullListsSchema, variables: %{"value" => [nil, 1]})
    end

  end

end
