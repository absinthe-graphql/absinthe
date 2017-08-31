defmodule Absinthe.CustomTypesTest do
  use Absinthe.Case, async: true
  import AssertResult

  defmodule Schema do
    use Absinthe.Schema

    import_types Absinthe.Type.Custom

    @custom_types %{
      datetime: %DateTime{
        year: 2017, month: 1, day: 27,
        hour: 20, minute: 31, second: 55,
        time_zone: "Etc/UTC", zone_abbr: "UTC", utc_offset: 0, std_offset: 0,
      },
      naive_datetime: ~N[2017-01-27 20:31:55],
      date: ~D[2017-01-27],
      time: ~T[20:31:55],
      decimal: Decimal.new("-3.49"),
    }

    query do
      field :custom_types_query, :custom_types_object do
        resolve fn _, _ -> {:ok, @custom_types} end
      end
    end

    mutation do
      field :custom_types_mutation, :result do
        arg :args, :custom_types_input
        resolve fn _, _ -> {:ok, %{message: "ok"}} end
      end
    end

    object :custom_types_object do
      field :datetime, :datetime
      field :naive_datetime, :naive_datetime
      field :date, :date
      field :time, :time
      field :decimal, :decimal
    end

    object :result do
      field :message, :string
    end

    input_object :custom_types_input do
      field :datetime, :datetime
      field :naive_datetime, :naive_datetime
      field :date, :date
      field :time, :time
      field :decimal, :decimal
    end
  end

  context "custom datetime type" do
    it "can use datetime type in queries" do
      result = "{ custom_types_query { datetime } }" |> run(Schema)
      assert_result {:ok, %{data: %{"custom_types_query" =>
        %{"datetime" => "2017-01-27T20:31:55Z"}}}}, result
    end
    it "can use datetime type in input_object" do
      request = """
      mutation {
        custom_types_mutation(args: { datetime: "2017-01-27T20:31:55Z" }) {
          message
        }
      }
      """
      result = run(request, Schema)
      assert_result {:ok, %{data: %{"custom_types_mutation" =>
        %{"message" => "ok"}}}}, result
    end
    it "can use null in input_object" do
      request = """
      mutation {
        custom_types_mutation(args: { datetime: null }) {
          message
        }
      }
      """
      result = run(request, Schema)
      assert_result {:ok, %{data: %{"custom_types_mutation" =>
        %{"message" => "ok"}}}}, result
    end
    it "returns an error when datetime value cannot be parsed" do
      request = """
      mutation {
        custom_types_mutation(args: { datetime: "abc" }) {
          message
        }
      }
      """
      assert {:ok, %{errors: _errors}} = run(request, Schema)
    end
  end

  context "custom naive datetime type" do
    it "can use naive datetime type in queries" do
      result = "{ custom_types_query { naive_datetime } }" |> run(Schema)
      assert_result {:ok, %{data: %{"custom_types_query" =>
        %{"naive_datetime" => "2017-01-27T20:31:55"}}}}, result
    end
    it "can use naive datetime type in input_object" do
      request = """
      mutation {
        custom_types_mutation(args: { naive_datetime: "2017-01-27T20:31:55" }) {
          message
        }
      }
      """
      result = run(request, Schema)
      assert_result {:ok, %{data: %{"custom_types_mutation" =>
        %{"message" => "ok"}}}}, result
    end
    it "can use null in input_object" do
      request = """
      mutation {
        custom_types_mutation(args: { naive_datetime: null }) {
          message
        }
      }
      """
      result = run(request, Schema)
      assert_result {:ok, %{data: %{"custom_types_mutation" =>
        %{"message" => "ok"}}}}, result
    end
    it "returns an error when naive datetime value cannot be parsed" do
      request = """
      mutation {
        custom_types_mutation(args: { naive_datetime: "abc" }) {
          message
        }
      }
      """
      assert {:ok, %{errors: _errors}} = run(request, Schema)
    end
  end

  context "custom date type" do
    it "can use date type in queries" do
      result = "{ custom_types_query { date } }" |> run(Schema)
      assert_result {:ok, %{data: %{"custom_types_query" =>
        %{"date" => "2017-01-27"}}}}, result
    end
    it "can use date type in input_object" do
      request = """
      mutation {
        custom_types_mutation(args: { date: "2017-01-27" }) {
          message
        }
      }
      """
      result = run(request, Schema)
      assert_result {:ok, %{data: %{"custom_types_mutation" =>
        %{"message" => "ok"}}}}, result
    end
    it "can use null in input_object" do
      request = """
      mutation {
        custom_types_mutation(args: { date: null }) {
          message
        }
      }
      """
      result = run(request, Schema)
      assert_result {:ok, %{data: %{"custom_types_mutation" =>
        %{"message" => "ok"}}}}, result
    end
    it "returns an error when date value cannot be parsed" do
      request = """
      mutation {
        custom_types_mutation(args: { date: "abc" }) {
          message
        }
      }
      """
      assert {:ok, %{errors: _errors}} = run(request, Schema)
    end
  end

  context "custom time type" do
    it "can use time type in queries" do
      result = "{ custom_types_query { time } }" |> run(Schema)
      assert_result {:ok, %{data: %{"custom_types_query" =>
      %{"time" => "20:31:55"}}}}, result
    end
    it "can use time type in input_object" do
      request = """
      mutation {
        custom_types_mutation(args: { time: "20:31:55" }) {
          message
        }
      }
      """
      result = run(request, Schema)
      assert_result {:ok, %{data: %{"custom_types_mutation" =>
        %{"message" => "ok"}}}}, result
    end
    it "can use null in input_object" do
      request = """
      mutation {
        custom_types_mutation(args: { time: null }) {
          message
        }
      }
      """
      result = run(request, Schema)
      assert_result {:ok, %{data: %{"custom_types_mutation" =>
        %{"message" => "ok"}}}}, result
    end
    it "returns an error when time value cannot be parsed" do
      request = """
      mutation {
        custom_types_mutation(args: { time: "abc" }) {
          message
        }
      }
      """
      assert {:ok, %{errors: _errors}} = run(request, Schema)
    end
  end

  context "custom decimal type" do
    it "can use decimal type in queries" do
      result = "{ custom_types_query { decimal } }" |> run(Schema)
      assert_result {:ok, %{data: %{"custom_types_query" =>
      %{"decimal" => "-3.49"}}}}, result
    end
    it "can use decimal type as string in input_object" do
      request = """
      mutation {
        custom_types_mutation(args: { decimal: "-3.49" }) {
          message
        }
      }
      """
      result = run(request, Schema)
      assert_result {:ok, %{data: %{"custom_types_mutation" =>
        %{"message" => "ok"}}}}, result
    end
    it "can use decimal type as integer in input_object" do
      request = """
      mutation {
        custom_types_mutation(args: { decimal: 3 }) {
          message
        }
      }
      """
      result = run(request, Schema)
      assert_result {:ok, %{data: %{"custom_types_mutation" =>
        %{"message" => "ok"}}}}, result
    end
    it "can use decimal type as float in input_object" do
      request = """
      mutation {
        custom_types_mutation(args: { decimal: -3.49 }) {
          message
        }
      }
      """
      result = run(request, Schema)
      assert_result {:ok, %{data: %{"custom_types_mutation" =>
        %{"message" => "ok"}}}}, result
    end
    it "can use null in input_object" do
      request = """
      mutation {
        custom_types_mutation(args: { decimal: null }) {
          message
        }
      }
      """
      result = run(request, Schema)
      assert_result {:ok, %{data: %{"custom_types_mutation" =>
        %{"message" => "ok"}}}}, result
    end
    it "returns an error when decimal value cannot be parsed" do
      request = """
      mutation {
        custom_types_mutation(args: { decimal: "abc" }) {
          message
        }
      }
      """
      assert {:ok, %{errors: _errors}} = run(request, Schema)
    end
  end
end
