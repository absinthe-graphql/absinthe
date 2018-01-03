defmodule GraphQL.Specification.NullValues.InputObjectTest do
  use Absinthe.Case, async: true

  defmodule Schema do
    use Absinthe.Schema

    query do

      field :obj_times, :integer do
        arg :input, non_null(:times_input)
        resolve fn
          _, %{input: %{base: base, multiplier: nil}}, _ ->
            {:ok, base}
          _, %{input: %{base: base, multiplier: num}}, _ ->
            {:ok, base * num}
        end
      end

    end

    input_object :times_input do
      field :multiplier, :integer, default_value: 2
      field :base, non_null(:integer)
    end

  end

  describe "as a literal" do

    describe "to a nullable input object field with a default value" do

      describe "(control): if not passed" do

        @query """
        { times: objTimes(input: {base: 4}) }
        """
        test "uses the default value" do
          assert_result {:ok, %{data: %{"times" => 8}}}, run(@query, Schema)
        end

      end

      describe "if passed" do

        @query """
        { times: objTimes(input: {base: 4, multiplier: null}) }
        """
        test "overrides the default and is passed as nil to the resolver" do
          assert_result {:ok, %{data: %{"times" => 4}}}, run(@query, Schema)
        end

      end

    end

    describe "to a non-nullable input object field" do

      describe "if passed" do

        @query """
        { times: objTimes(input: {base: null}) }
        """
        test "adds an error" do
          assert_result {:ok, %{errors: [%{message: "Argument \"input\" has invalid value {base: null}.\nIn field \"base\": Expected type \"Int!\", found null."}]}}, run(@query, Schema)
        end

      end

    end

  end

 describe "as a variable" do

    describe "to a nullable input object field with a default value" do

      describe "if passed" do

        @query """
        query ($value: Int) { times: objTimes(input: {base: 4, multiplier: $value}) }
        """
        test "overrides the default and is passed as nil to the resolver" do
          assert_result {:ok, %{data: %{"times" => 4}}}, run(@query, Schema, variables: %{"value" => nil})
        end

      end

    end

    describe "to a non-nullable input object field" do

      describe "if passed" do

        @query """
        query ($value: Int!) { times: objTimes(input: {base: $value}) }
        """
        test "adds an error" do
          assert_result {:ok, %{errors: [%{message: "Argument \"input\" has invalid value {base: $value}.\nIn field \"base\": Expected type \"Int!\", found $value."}, %{message: "Variable \"value\": Expected non-null, found null."}]}}, run(@query, Schema, variables: %{"value" => nil})
        end

      end

    end

  end

end
