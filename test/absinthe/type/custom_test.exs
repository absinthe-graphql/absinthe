defmodule Absinthe.Type.CustomTest do
  use Absinthe.Case, async: true

  alias Absinthe.Type
  alias Absinthe.Blueprint.Input

  defmodule TestSchema do
    use Absinthe.Schema
    import_types Type.Custom

    query do
    end
  end

  @datetime %DateTime{
    year: 2017,
    month: 1,
    day: 27,
    hour: 20,
    minute: 31,
    second: 55,
    time_zone: "Etc/UTC",
    zone_abbr: "UTC",
    utc_offset: 0,
    std_offset: 0
  }

  @naive_datetime ~N[2017-01-27 20:31:55]
  @date ~D[2017-01-27]
  @time ~T[20:31:55]
  @decimal Decimal.new("-3.49")
  @decimal_int Decimal.new("3")

  defp serialize(type, value) do
    TestSchema.__absinthe_type__(type)
    |> Type.Scalar.serialize(value)
  end

  defp parse(type, value) do
    TestSchema.__absinthe_type__(type)
    |> Type.Scalar.parse(value)
  end

  describe ":datetime" do
    test "serializes as an ISO8601 date and time string with UTC timezone marker" do
      assert "2017-01-27T20:31:55Z" == serialize(:datetime, @datetime)
    end

    test "can be parsed from an ISO8601 date and time string including timezone" do
      assert {:ok, @datetime} == parse(:datetime, %Input.String{value: "2017-01-27T20:31:55Z"})
      assert {:ok, @datetime} == parse(:datetime, %Input.String{value: "2017-01-27 20:31:55Z"})
    end

    test "can be parsed from an ISO8601 date and time string including zero UTC offset" do
      assert {:ok, @datetime} ==
               parse(:datetime, %Input.String{value: "2017-01-27T20:31:55+00:00"})
    end

    test "can be parsed when a non-zero UTC offset is included" do
      assert {:ok, @datetime} ==
               parse(:datetime, %Input.String{value: "2017-01-27T18:01:55-02:30"})

      assert {:ok, @datetime} ==
               parse(:datetime, %Input.String{value: "2017-01-28T00:31:55+04:00"})
    end

    test "cannot be parsed without UTC timezone marker" do
      assert :error == parse(:datetime, %Input.String{value: "2017-01-27T20:31:55"})
      assert :error == parse(:datetime, %Input.String{value: "2017-01-27 20:31:55"})
    end

    test "cannot be parsed when date or time is missing" do
      assert :error == parse(:datetime, %Input.String{value: "2017-01-27"})
      assert :error == parse(:datetime, %Input.String{value: "20:31:55"})
    end

    test "cannot be parsed from a binary not formatted according to ISO8601" do
      assert :error == parse(:datetime, %Input.String{value: "abc123"})
      assert :error == parse(:datetime, %Input.String{value: "01/25/2017 20:31:55"})
      assert :error == parse(:datetime, %Input.String{value: "2017-15-42T31:71:95Z"})
    end
  end

  describe ":naive_datetime" do
    test "serializes as an ISO8601 date and time string" do
      assert "2017-01-27T20:31:55" == serialize(:naive_datetime, @naive_datetime)
    end

    test "can be parsed from an ISO8601 date and time string" do
      assert {:ok, @naive_datetime} ==
               parse(:naive_datetime, %Input.String{value: "2017-01-27T20:31:55Z"})

      assert {:ok, @naive_datetime} ==
               parse(:naive_datetime, %Input.String{value: "2017-01-27 20:31:55Z"})

      assert {:ok, @naive_datetime} ==
               parse(:naive_datetime, %Input.String{value: "2017-01-27 20:31:55"})
    end

    test "cannot be parsed when date or time is missing" do
      assert :error == parse(:naive_datetime, %Input.String{value: "2017-01-27"})
      assert :error == parse(:naive_datetime, %Input.String{value: "20:31:55"})
    end

    test "cannot be parsed from a binary not formatted according to ISO8601" do
      assert :error == parse(:naive_datetime, %Input.String{value: "abc123"})
      assert :error == parse(:naive_datetime, %Input.String{value: "01/25/2017 20:31:55"})
      assert :error == parse(:naive_datetime, %Input.String{value: "2017-15-42T31:71:95"})
    end
  end

  describe ":date" do
    test "serializes as an ISO8601 date string" do
      assert "2017-01-27" == serialize(:date, @date)
    end

    test "can be parsed from an ISO8601 date string" do
      assert {:ok, @date} == parse(:date, %Input.String{value: "2017-01-27"})
    end

    test "cannot be parsed when time is included" do
      assert :error == parse(:date, %Input.String{value: "2017-01-27T20:31:55Z"})
      assert :error == parse(:date, %Input.String{value: "2017-01-27 20:31:55Z"})
      assert :error == parse(:date, %Input.String{value: "2017-01-27 20:31:55"})
    end

    test "cannot be parsed when date is missing" do
      assert :error == parse(:date, %Input.String{value: "20:31:55"})
    end

    test "cannot be parsed from a binary not formatted according to ISO8601" do
      assert :error == parse(:date, %Input.String{value: "abc123"})
      assert :error == parse(:date, %Input.String{value: "01/25/2017 20:31:55"})
      assert :error == parse(:date, %Input.String{value: "2017-15-42T31:71:95Z"})
    end
  end

  describe ":time" do
    test "serializes as an ISO8601 time string" do
      assert "20:31:55" == serialize(:time, @time)
    end

    test "can be parsed from an ISO8601 date string" do
      assert {:ok, @time} == parse(:time, %Input.String{value: "20:31:55"})
    end

    test "cannot be parsed when date is included" do
      assert :error == parse(:time, %Input.String{value: "2017-01-27T20:31:55Z"})
      assert :error == parse(:time, %Input.String{value: "2017-01-27 20:31:55Z"})
      assert :error == parse(:time, %Input.String{value: "2017-01-27 20:31:55"})
    end

    test "cannot be parsed when time is missing" do
      assert :error == parse(:time, %Input.String{value: "2017-01-27"})
    end

    test "cannot be parsed from a binary not formatted according to ISO8601" do
      assert :error == parse(:time, %Input.String{value: "abc123"})
      assert :error == parse(:time, %Input.String{value: "01/25/2017 20:31:55"})
      assert :error == parse(:time, %Input.String{value: "2017-15-42T31:71:95Z"})
    end
  end

  describe ":decimal" do
    test "serializes as a string" do
      assert "-3.49" == serialize(:decimal, @decimal)
      assert "3" == serialize(:decimal, @decimal_int)
    end

    test "can be parsed from a numeric string" do
      assert {:ok, decimal} = parse(:decimal, %Input.String{value: "-3.49"})
      assert Decimal.compare(@decimal, decimal) == :eq
    end

    test "can be parsed from a float" do
      assert {:ok, decimal} = parse(:decimal, %Input.Float{value: -3.49})
      assert Decimal.compare(@decimal, decimal) == :eq
    end

    test "can be parsed from an integer" do
      assert {:ok, decimal} = parse(:decimal, %Input.Integer{value: 3})
      assert Decimal.compare(@decimal_int, decimal) == :eq
    end

    test "cannot be parsed from alphanumeric string" do
      assert :error == parse(:decimal, %Input.String{value: "23.4 abc"})
    end
  end
end
