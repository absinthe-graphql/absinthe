defmodule Absinthe.CustomTypesTest do
  use Absinthe.Case, async: true

  describe "custom datetime type" do
    test "can use null in input_object" do
      request = """
      mutation {
        custom_types_mutation(args: { datetime: null }) {
          message
        }
      }
      """

      result = run(request, Absinthe.Fixtures.CustomTypesSchema)
      assert_result({:ok, %{data: %{"custom_types_mutation" => %{"message" => "ok"}}}}, result)
    end

    test "returns an error when datetime value cannot be parsed" do
      request = """
      mutation {
        custom_types_mutation(args: { datetime: "abc" }) {
          message
        }
      }
      """

      assert {:ok, %{errors: _errors}} = run(request, Absinthe.Fixtures.CustomTypesSchema)
    end
  end

  describe "custom naive datetime type" do
    test "can use naive datetime type in queries" do
      result =
        "{ custom_types_query { naive_datetime } }" |> run(Absinthe.Fixtures.CustomTypesSchema)

      assert_result(
        {:ok, %{data: %{"custom_types_query" => %{"naive_datetime" => "2017-01-27T20:31:55"}}}},
        result
      )
    end

    test "can use naive datetime type in input_object" do
      request = """
      mutation {
        custom_types_mutation(args: { naive_datetime: "2017-01-27T20:31:55" }) {
          message
        }
      }
      """

      result = run(request, Absinthe.Fixtures.CustomTypesSchema)
      assert_result({:ok, %{data: %{"custom_types_mutation" => %{"message" => "ok"}}}}, result)
    end

    test "can use null in input_object" do
      request = """
      mutation {
        custom_types_mutation(args: { naive_datetime: null }) {
          message
        }
      }
      """

      result = run(request, Absinthe.Fixtures.CustomTypesSchema)
      assert_result({:ok, %{data: %{"custom_types_mutation" => %{"message" => "ok"}}}}, result)
    end

    test "returns an error when naive datetime value cannot be parsed" do
      request = """
      mutation {
        custom_types_mutation(args: { naive_datetime: "abc" }) {
          message
        }
      }
      """

      assert {:ok, %{errors: _errors}} = run(request, Absinthe.Fixtures.CustomTypesSchema)
    end
  end

  describe "custom date type" do
    test "can use date type in queries" do
      result = "{ custom_types_query { date } }" |> run(Absinthe.Fixtures.CustomTypesSchema)
      assert_result({:ok, %{data: %{"custom_types_query" => %{"date" => "2017-01-27"}}}}, result)
    end

    test "can use date type in input_object" do
      request = """
      mutation {
        custom_types_mutation(args: { date: "2017-01-27" }) {
          message
        }
      }
      """

      result = run(request, Absinthe.Fixtures.CustomTypesSchema)
      assert_result({:ok, %{data: %{"custom_types_mutation" => %{"message" => "ok"}}}}, result)
    end

    test "can use null in input_object" do
      request = """
      mutation {
        custom_types_mutation(args: { date: null }) {
          message
        }
      }
      """

      result = run(request, Absinthe.Fixtures.CustomTypesSchema)
      assert_result({:ok, %{data: %{"custom_types_mutation" => %{"message" => "ok"}}}}, result)
    end

    test "returns an error when date value cannot be parsed" do
      request = """
      mutation {
        custom_types_mutation(args: { date: "abc" }) {
          message
        }
      }
      """

      assert {:ok, %{errors: _errors}} = run(request, Absinthe.Fixtures.CustomTypesSchema)
    end
  end

  describe "custom time type" do
    test "can use time type in queries" do
      result = "{ custom_types_query { time } }" |> run(Absinthe.Fixtures.CustomTypesSchema)
      assert_result({:ok, %{data: %{"custom_types_query" => %{"time" => "20:31:55"}}}}, result)
    end

    test "can use time type in input_object" do
      request = """
      mutation {
        custom_types_mutation(args: { time: "20:31:55" }) {
          message
        }
      }
      """

      result = run(request, Absinthe.Fixtures.CustomTypesSchema)
      assert_result({:ok, %{data: %{"custom_types_mutation" => %{"message" => "ok"}}}}, result)
    end

    test "can use null in input_object" do
      request = """
      mutation {
        custom_types_mutation(args: { time: null }) {
          message
        }
      }
      """

      result = run(request, Absinthe.Fixtures.CustomTypesSchema)
      assert_result({:ok, %{data: %{"custom_types_mutation" => %{"message" => "ok"}}}}, result)
    end

    test "returns an error when time value cannot be parsed" do
      request = """
      mutation {
        custom_types_mutation(args: { time: "abc" }) {
          message
        }
      }
      """

      assert {:ok, %{errors: _errors}} = run(request, Absinthe.Fixtures.CustomTypesSchema)
    end
  end

  describe "custom decimal type" do
    test "can use decimal type in queries" do
      result = "{ custom_types_query { decimal } }" |> run(Absinthe.Fixtures.CustomTypesSchema)
      assert_result({:ok, %{data: %{"custom_types_query" => %{"decimal" => "-3.49"}}}}, result)
    end

    test "can use decimal type as string in input_object" do
      request = """
      mutation {
        custom_types_mutation(args: { decimal: "-3.49" }) {
          message
        }
      }
      """

      result = run(request, Absinthe.Fixtures.CustomTypesSchema)
      assert_result({:ok, %{data: %{"custom_types_mutation" => %{"message" => "ok"}}}}, result)
    end

    test "can use decimal type as integer in input_object" do
      request = """
      mutation {
        custom_types_mutation(args: { decimal: 3 }) {
          message
        }
      }
      """

      result = run(request, Absinthe.Fixtures.CustomTypesSchema)
      assert_result({:ok, %{data: %{"custom_types_mutation" => %{"message" => "ok"}}}}, result)
    end

    test "can use decimal type as float in input_object" do
      request = """
      mutation {
        custom_types_mutation(args: { decimal: -3.49 }) {
          message
        }
      }
      """

      result = run(request, Absinthe.Fixtures.CustomTypesSchema)
      assert_result({:ok, %{data: %{"custom_types_mutation" => %{"message" => "ok"}}}}, result)
    end

    test "can use null in input_object" do
      request = """
      mutation {
        custom_types_mutation(args: { decimal: null }) {
          message
        }
      }
      """

      result = run(request, Absinthe.Fixtures.CustomTypesSchema)
      assert_result({:ok, %{data: %{"custom_types_mutation" => %{"message" => "ok"}}}}, result)
    end

    test "returns an error when decimal value cannot be parsed" do
      request = """
      mutation {
        custom_types_mutation(args: { decimal: "abc" }) {
          message
        }
      }
      """

      assert {:ok, %{errors: _errors}} = run(request, Absinthe.Fixtures.CustomTypesSchema)
    end
  end
end
