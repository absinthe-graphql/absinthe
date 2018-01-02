defmodule GraphQL.Specification.NullValues.ListTest do
  use Absinthe.Case, async: true
  import AssertResult

  defmodule Schema do
    use Absinthe.Schema

    query do

      field :nullable_list, :list_details do
        arg :input, list_of(:integer)
        resolve fn
          _, %{input: nil}, _ ->
            {:ok, nil}
          _, %{input: list}, _ ->
            {
              :ok,
              %{
                length: length(list),
                content: list,
                null_count: Enum.count(list, &(&1 == nil)),
                non_null_count: Enum.count(list, &(&1 != nil)),
              }
            }
        end
      end

      field :non_nullable_list, :list_details do
        arg :input, non_null(list_of(:integer))
        resolve fn
          _, %{input: list}, _ ->
            {
              :ok,
              %{
                length: length(list),
                content: list,
                null_count: Enum.count(list, &(&1 == nil)),
                non_null_count: Enum.count(list, &(&1 != nil)),
              }
            }
        end
      end

      field :nullable_list_of_non_nullable_type, :list_details do
        arg :input, list_of(non_null(:integer))
        resolve fn
          _, %{input: nil}, _ ->
            {:ok, nil}
          _, %{input: list}, _ ->
            {
              :ok,
              %{
                length: length(list),
                content: list,
                null_count: Enum.count(list, &(&1 == nil)),
                non_null_count: Enum.count(list, &(&1 != nil)),
              }
            }
        end
      end

      field :non_nullable_list_of_non_nullable_type, :list_details do
        arg :input, non_null(list_of(non_null(:integer)))
        resolve fn
          _, %{input: list}, _ ->
            {
              :ok,
              %{
                length: length(list),
                content: list,
                null_count: Enum.count(list, &(&1 == nil)),
                non_null_count: Enum.count(list, &(&1 != nil)),
              }
            }
        end
      end

    end

    object :list_details do
      field :length, :integer
      field :content, list_of(:integer)
      field :null_count, :integer
      field :non_null_count, :integer
    end

  end

  describe "as a literal" do

    describe "to an [Int]" do

      describe "if passed as the value" do
        @query """
        {
          nullableList(input: null) {
            length
            content
            nonNullCount
            nullCount
          }
        }
        """
        test "is treated as a null argument" do
          assert_result {
            :ok,
            %{
              data: %{
                "nullableList" => nil
              }
            }
          }, run(@query, Schema)
        end
      end

      describe "if passed as an element" do
        @query """
        {
          nullableList(input: [null, 1]) {
            length
            content
            nonNullCount
            nullCount
          }
        }
        """
        test "is treated as a valid value" do
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
          }, run(@query, Schema)
        end
      end

    end

    describe "to an [Int]!" do

      describe "if passed as the value" do
        @query """
        {
          nonNullableList(input: null) {
            length
            content
            nonNullCount
            nullCount
          }
        }
        """
        test "is treated as a null argument" do
          assert_result {
            :ok,
            %{
              errors: [%{message: "Argument \"input\" has invalid value null."}]
            }
          }, run(@query, Schema)
        end
      end

      describe "if passed as an element" do
        @query """
        {
          nonNullableList(input: [null, 1]) {
            length
            content
            nonNullCount
            nullCount
          }
        }
        """
        test "is treated as a valid value" do
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
          }, run(@query, Schema)
        end
      end

    end

    describe "to an [Int!]" do

      describe "if passed as the value" do
        @query """
        {
          nullableListOfNonNullableType(input: null) {
            length
            content
            nonNullCount
            nullCount
          }
        }
        """
        test "is treated as a null argument" do
          assert_result {
            :ok,
            %{
              data: %{
                "nullableListOfNonNullableType" => nil
              }
            }
          }, run(@query, Schema)
        end
      end

      describe "if passed as an element" do
        @query """
        {
          nullableListOfNonNullableType(input: [null, 1]) {
            length
            content
            nonNullCount
            nullCount
          }
        }
        """
        test "returns an error" do
          assert_result {
            :ok,
            %{
              errors: [
                %{message: "Argument \"input\" has invalid value [null, 1].\nIn element #1: Expected type \"Int!\", found null."}
              ]
            }
          }, run(@query, Schema)
        end
      end

    end

    describe "to an [Int!]!" do

      describe "if passed as the value" do
        @query """
        {
          nonNullableListOfNonNullableType(input: null) {
            length
            content
            nonNullCount
            nullCount
          }
        }
        """
        test "is treated as a null argument" do
          assert_result {
            :ok,
            %{
              errors: [%{message: "Argument \"input\" has invalid value null."}]
            }
          }, run(@query, Schema)
        end
      end

      describe "if passed as an element" do
        @query """
        {
          nonNullableListOfNonNullableType(input: [null, 1]) {
            length
            content
            nonNullCount
            nullCount
          }
        }
        """
        test "returns an error" do
          assert_result {
            :ok,
            %{
              errors: [
                %{message: "Argument \"input\" has invalid value [null, 1].\nIn element #1: Expected type \"Int!\", found null."}
              ]
            }
          }, run(@query, Schema)
        end
      end

    end

  end

 describe "as a variable" do

    describe "to an [Int]" do

      describe "if passed as the value" do
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
        test "is treated as a null argument" do
          assert_result {
            :ok,
            %{
              data: %{
                "nullableList" => nil
              }
            }
          }, run(@query, Schema, variables: %{"value" => nil})
        end
      end

      describe "if passed as an element" do
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
        test "is treated as a valid value" do
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
          }, run(@query, Schema, variables: %{"value" => [nil, 1]})
        end
      end

    end

    describe "to an [Int]!" do

      describe "if passed as the value" do
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
        test "is treated as a null argument" do
          assert_result {
            :ok,
            %{
              errors: [%{message: "Argument \"input\" has invalid value $value."}, %{message: "Variable \"value\": Expected non-null, found null."}]
            }
          }, run(@query, Schema, variables: %{"value" => nil})
        end
      end

      describe "if passed as an element" do
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
        test "is treated as a valid value" do
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
          }, run(@query, Schema, variables: %{"value" => [nil, 1]})
        end
      end

    end

    describe "to an [Int!]" do

      describe "if passed as the value" do
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
        test "is treated as a null argument" do
          assert_result {
            :ok,
            %{
              data: %{
                "nullableListOfNonNullableType" => nil
              }
            }
          }, run(@query, Schema, variables: %{"value" => nil})
        end
      end

      describe "if passed as an element" do
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
        test "returns an error" do
          assert_result {
            :ok,
            %{
              errors: [
                %{message: "Argument \"input\" has invalid value $value.\nIn element #1: Expected type \"Int!\", found null."}
              ]
            }
          }, run(@query, Schema, variables: %{"value" => [nil, 1]})
        end
      end

    end

    describe "to an [Int!]!" do

      describe "if passed as the value" do
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
        test "is treated as a null argument" do
          assert_result {
            :ok,
            %{
              errors: [%{message: "Argument \"input\" has invalid value $value."}, %{message: "Variable \"value\": Expected non-null, found null."}]
            }
          }, run(@query, Schema, variables: %{"value" => nil})
        end
      end

      describe "if passed as an element" do
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
        @tag :check
        test "returns an error" do
          assert_result {
            :ok,
            %{
              errors: [
                %{message: "Argument \"input\" has invalid value $value.\nIn element #1: Expected type \"Int!\", found null."}
              ]
            }
          }, run(@query, Schema, variables: %{"value" => [nil, 1]})
        end
      end

    end

  end

end
