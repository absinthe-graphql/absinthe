defmodule GraphQL.Specification.NullValuesTest do
  use Absinthe.Case, async: true
  import AssertResult


  defmodule Schema do
    use Absinthe.Schema

    query do

      field :times, :integer do

        arg :multiplier, :integer, default_value: 2
        arg :base, non_null(:integer)

        resolve fn
          _, %{base: base, multiplier: nil}, _ ->
            {:ok, base}
          _, %{base: base, multiplier: num}, _ ->
            {:ok, base * num}
        end

      end

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

    describe "to a nullable argument with a default value" do

      describe "(control): if not passed" do

        @query """
        { times(base: 4) }
        """
        it "uses the default value" do
          assert_result {:ok, %{data: %{"times" => 8}}}, run(@query, Schema)
        end

      end

      describe "if passed" do

        @query """
        { times(base: 4, multiplier: null) }
        """
        it "overrides the default and is passed as nil to the resolver" do
          assert_result {:ok, %{data: %{"times" => 4}}}, run(@query, Schema)
        end

      end

    end

    describe "to a nullable input object field with a default value" do

      describe "(control): if not passed" do

        @query """
        { times: objTimes(input: {base: 4}) }
        """
        it "uses the default value" do
          assert_result {:ok, %{data: %{"times" => 8}}}, run(@query, Schema)
        end

      end

      describe "if passed" do

        @query """
        { times: objTimes(input: {base: 4, multiplier: null}) }
        """
        it "overrides the default and is passed as nil to the resolver" do
          assert_result {:ok, %{data: %{"times" => 4}}}, run(@query, Schema)
        end

      end

    end

    describe "to a non-nullable argument" do

      describe "if passed" do

        @query """
        { times(base: null) }
        """
        it "adds an error" do
          assert_result {:ok, %{errors: [%{message: "Argument \"base\" has invalid value null."}]}}, run(@query, Schema)
        end

      end

    end

    describe "to a non-nullable input object field" do

      describe "if passed" do

        @query """
        { times: objTimes(input: {base: null}) }
        """
        it "adds an error" do
          assert_result {:ok, %{errors: [%{message: "Argument \"input\" has invalid value {base: null}.\nIn field \"base\": Expected type \"Int!\", found null."}]}}, run(@query, Schema)
        end

      end

    end


  end

  describe "as a variable value" do

    describe "to a variable with a default value" do

      describe "if not passed (control)" do

        @query """
        query Test($mult: Int = 6) { times(base: 4, multiplier: $mult) }
        """
        it "uses the default variable value" do
          assert_result {:ok, %{data: %{"times" => 24}}}, run(@query, Schema)
        end

      end

      describe "if passed" do

        @query """
        query Test($mult: Int = 6) { times(base: 4, multiplier: $mult) }
        """
        it "overrides the default and is passed as nil to the resolver" do
          assert_result {:ok, %{data: %{"times" => 4}}}, run(@query, Schema, variables: %{"mult" => nil})
        end

      end

    end

    describe "to a non-nullable variable" do

      describe "if passed" do

        @query """
        query Test($mult: Int!) { times(base: 4, multiplier: $mult) }
        """
        # Needs non-nullable variable validation (missing)
        @tag :pending
        it "adds an error" do

        end

      end

    end

  end

end
