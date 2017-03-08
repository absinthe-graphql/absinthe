defmodule Absinthe.Type.CustomTest do
  use Absinthe.Case, async: true

  alias Absinthe.Type

  defmodule TestSchema do
    use Absinthe.Schema
    import_types Type.Custom
  end

  @datetime %DateTime{
    year: 2017, month: 1, day: 27,
    hour: 20, minute: 31, second: 55,
    time_zone: "Etc/UTC", zone_abbr: "UTC", utc_offset: 0, std_offset: 0,
  }

  @naive_datetime ~N[2017-01-27 20:31:55]
  @date ~D[2017-01-27]
  @time ~T[20:31:55]

  defp serialize(type, value) do
    TestSchema.__absinthe_type__(type)
    |> Type.Scalar.serialize(value)
  end

  defp parse(type, value) do
    TestSchema.__absinthe_type__(type)
    |> Type.Scalar.parse(value)
  end

  describe ":datetime" do
    it "serializes as an ISO8601 date and time string with UTC timezone marker" do
      assert "2017-01-27T20:31:55Z" == serialize(:datetime, @datetime)
    end

    it "can be parsed from an ISO8601 date and time string including timezone" do
      assert {:ok, @datetime} == parse(:datetime, "2017-01-27T20:31:55Z")
      assert {:ok, @datetime} == parse(:datetime, "2017-01-27 20:31:55Z")
    end

    it "can be parsed from an ISO8601 date and time string including zero UTC offset" do
      assert {:ok, @datetime} == parse(:datetime, "2017-01-27T20:31:55+00:00")
    end

    it "cannot be parsed when a non-zero UTC offset is included" do
      assert :error == parse(:datetime, "2017-01-27T20:31:55-02:30")
      assert :error == parse(:datetime, "2017-01-27T20:31:55+04:00")
    end

    it "cannot be parsed without UTC timezone marker" do
      assert :error == parse(:datetime, "2017-01-27T20:31:55")
      assert :error == parse(:datetime, "2017-01-27 20:31:55")
    end

    it "cannot be parsed when date or time is missing" do
      assert :error == parse(:datetime, "2017-01-27")
      assert :error == parse(:datetime, "20:31:55")
    end

    it "cannot be parsed from a binary not formatted according to ISO8601" do
      assert :error == parse(:datetime, "abc123")
      assert :error == parse(:datetime, "01/25/2017 20:31:55")
      assert :error == parse(:datetime, "2017-15-42T31:71:95Z")
    end

    it "cannot be parsed from a number" do
      assert :error == parse(:datetime, 0)
      assert :error == parse(:datetime, 0.0)
    end

    it "cannot be parsed from a boolean" do
      assert :error == parse(:datetime, true)
      assert :error == parse(:datetime, false)
    end
  end

  describe ":naive_datetime" do
    it "serializes as an ISO8601 date and time string" do
      assert "2017-01-27T20:31:55" == serialize(:naive_datetime, @naive_datetime)
    end

    it "can be parsed from an ISO8601 date and time string" do
      assert {:ok, @naive_datetime} == parse(:naive_datetime, "2017-01-27T20:31:55Z")
      assert {:ok, @naive_datetime} == parse(:naive_datetime, "2017-01-27 20:31:55Z")
      assert {:ok, @naive_datetime} == parse(:naive_datetime, "2017-01-27 20:31:55")
    end

    it "cannot be parsed when date or time is missing" do
      assert :error == parse(:naive_datetime, "2017-01-27")
      assert :error == parse(:naive_datetime, "20:31:55")
    end

    it "cannot be parsed from a binary not formatted according to ISO8601" do
      assert :error == parse(:naive_datetime, "abc123")
      assert :error == parse(:naive_datetime, "01/25/2017 20:31:55")
      assert :error == parse(:naive_datetime, "2017-15-42T31:71:95")
    end

    it "cannot be parsed from a number" do
      assert :error == parse(:naive_datetime, 0)
      assert :error == parse(:naive_datetime, 0.0)
    end

    it "cannot be parsed from a boolean" do
      assert :error == parse(:naive_datetime, true)
      assert :error == parse(:naive_datetime, false)
    end
  end

  describe ":date" do
    it "serializes as an ISO8601 date string" do
      assert "2017-01-27" == serialize(:date, @date)
    end

    it "can be parsed from an ISO8601 date string" do
      assert {:ok, @date} == parse(:date, "2017-01-27")
    end

    it "cannot be parsed when time is included" do
      assert :error == parse(:date, "2017-01-27T20:31:55Z")
      assert :error == parse(:date, "2017-01-27 20:31:55Z")
      assert :error == parse(:date, "2017-01-27 20:31:55")
    end

    it "cannot be parsed when date is missing" do
      assert :error == parse(:date, "20:31:55")
    end

    it "cannot be parsed from a binary not formatted according to ISO8601" do
      assert :error == parse(:date, "abc123")
      assert :error == parse(:date, "01/25/2017 20:31:55")
      assert :error == parse(:date, "2017-15-42T31:71:95Z")
    end

    it "cannot be parsed from a number" do
      assert :error == parse(:date, 0)
      assert :error == parse(:date, 0.0)
    end

    it "cannot be parsed from a boolean" do
      assert :error == parse(:date, true)
      assert :error == parse(:date, false)
    end
  end

  describe ":time" do
    it "serializes as an ISO8601 time string" do
      assert "20:31:55" == serialize(:time, @time)
    end

    it "can be parsed from an ISO8601 date string" do
      assert {:ok, @time} == parse(:time, "20:31:55")
    end

    it "cannot be parsed when date is included" do
      assert :error == parse(:time, "2017-01-27T20:31:55Z")
      assert :error == parse(:time, "2017-01-27 20:31:55Z")
      assert :error == parse(:time, "2017-01-27 20:31:55")
    end

    it "cannot be parsed when time is missing" do
      assert :error == parse(:time, "2017-01-27")
    end

    it "cannot be parsed from a binary not formatted according to ISO8601" do
      assert :error == parse(:time, "abc123")
      assert :error == parse(:time, "01/25/2017 20:31:55")
      assert :error == parse(:time, "2017-15-42T31:71:95Z")
    end

    it "cannot be parsed from a number" do
      assert :error == parse(:time, 0)
      assert :error == parse(:time, 0.0)
    end

    it "cannot be parsed from a boolean" do
      assert :error == parse(:time, true)
      assert :error == parse(:time, false)
    end
  end
end
