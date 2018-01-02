defmodule GraphQL.Specification.NullValues.ScalarTest do
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
          _, %{base: _}, _ ->
            {:error, "Didn't get any multiplier"}
        end

      end

    end

  end

  context "as a literal" do

    context "to a nullable argument with a default value" do

      context "(control): if not passed" do

        @query """
        { times(base: 4) }
        """
        test "uses the default value" do
          assert_result {:ok, %{data: %{"times" => 8}}}, run(@query, Schema)
        end

      end

      context "if passed" do

        @query """
        { times(base: 4, multiplier: null) }
        """
        test "overrides the default and is passed as nil to the resolver" do
          assert_result {:ok, %{data: %{"times" => 4}}}, run(@query, Schema)
        end

      end

    end

    context "to a non-nullable argument" do

      context "if passed" do

        @query """
        { times(base: null) }
        """
        test "adds an error" do
          assert_result {:ok, %{errors: [%{message: "Argument \"base\" has invalid value null."}]}}, run(@query, Schema)
        end

      end

    end

  end

  context "as a variable value" do

    context "to a variable with a default value" do

      context "if not passed (control)" do

        @query """
        query Test($mult: Int = 6) { times(base: 4, multiplier: $mult) }
        """
        test "uses the default variable value" do
          assert_result {:ok, %{data: %{"times" => 24}}}, run(@query, Schema)
        end

      end

      context "if passed" do

        @query """
        query Test($mult: Int = 6) { times(base: 4, multiplier: $mult) }
        """
        test "overrides the default and is passed as nil to the resolver" do
          assert_result {:ok, %{data: %{"times" => 4}}}, run(@query, Schema, variables: %{"mult" => nil})
        end

      end

    end

    context "to a non-nullable variable" do

      context "if passed" do

        @query """
        query Test($mult: Int!) { times(base: 4, multiplier: $mult) }
        """
        test "adds an error" do
          assert_result {:ok, %{errors: [%{message: "Variable \"mult\": Expected non-null, found null."}]}}, run(@query, Schema, variables: %{"mult" => nil})
        end

      end

    end

  end

end
