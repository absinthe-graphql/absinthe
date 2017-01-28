defmodule Absinthe.Type.BuliltIns.ScalarsTest do
  use Absinthe.Case, async: true

  alias Absinthe.Type

  defmodule TestSchema do
    use Absinthe.Schema
  end

  @max_int 9007199254740991
  @min_int -9007199254740991
  @utc_datetime %DateTime{
    year: 2017, month: 1, day: 27,
    hour: 20, minute: 31, second: 55,
    time_zone: "Etc/UTC", zone_abbr: "UTC", utc_offset: 0, std_offset: 0,
  }
  @datetime ~N[2017-01-27 20:31:55]
  @date ~D[2017-01-27]

  defp serialize(type, value) do
    TestSchema.__absinthe_type__(type)
    |> Type.Scalar.serialize(value)
  end

  defp parse(type, value) do
    TestSchema.__absinthe_type__(type)
    |> Type.Scalar.parse(value)
  end

  describe ":integer" do
    it "serializes as an integer" do
      assert 1 == serialize(:integer, 1)
    end

    it "can be parsed from an integer within the valid range" do
      assert {:ok, 0} == parse(:integer, 0)
      assert {:ok, 1} == parse(:integer, 1)
      assert {:ok, -1} == parse(:integer, -1)
      assert {:ok, @max_int} == parse(:integer, @max_int)
      assert {:ok, @min_int} == parse(:integer, @min_int)
      assert :error == parse(:integer, @max_int + 1)
      assert :error == parse(:integer, @min_int - 1)
    end

    it "cannot be parsed from a float" do
      assert :error == parse(:integer, 0.0)
    end

    it "cannot be parsed from a binary" do
      assert :error == parse(:integer, "")
      assert :error == parse(:integer, "0")
    end
  end

  describe ":float" do
    it "serializes as a float" do
      assert 1.0 == serialize(:float, 1.0)
    end

    it "can be parsed from an integer" do
      assert {:ok, 0.0} == parse(:float, 0)
      assert {:ok, 1.0} == parse(:float, 1)
      assert {:ok, -1.0} == parse(:float, -1)
    end

    it "can be parsed from a float" do
      assert {:ok, 0.0} == parse(:float, 0.0)
      assert {:ok, 1.9} == parse(:float, 1.9)
      assert {:ok, -1.9} == parse(:float, -1.9)
    end

    it "cannot be parsed from a binary" do
      assert :error == parse(:float, "")
      assert :error == parse(:float, "0.0")
    end
  end

  describe ":string" do
    it "serializes as a string" do
      assert "" == serialize(:string, "")
      assert "string" == serialize(:string, "string")
    end

    it "can be parsed from a binary" do
      assert {:ok, ""} == parse(:string, "")
      assert {:ok, "string"} == parse(:string, "string")
    end

    it "cannot be parsed from an integer" do
      assert :error == parse(:string, 0)
    end

    it "cannot be parsed from a float" do
      assert :error == parse(:string, 1.9)
    end
  end

  describe ":id" do
    it "serializes as a string" do
      assert "1" == serialize(:id, 1)
      assert "1" == serialize(:id, "1")
    end

    it "can be parsed from a binary" do
      assert {:ok, ""} == parse(:id, "")
      assert {:ok, "abc123"} == parse(:id, "abc123")
    end

    it "can be parsed from an integer" do
      assert {:ok, "0"} == parse(:id, 0)
      assert {:ok, Integer.to_string(@max_int)} == parse(:id, @max_int)
      assert {:ok, Integer.to_string(@min_int)} == parse(:id, @min_int)
    end

    it "cannot be parsed from a float" do
      assert :error == parse(:id, 1.9)
    end
  end

  describe ":boolean" do
    it "serializes as a boolean" do
      assert true == serialize(:boolean, true)
      assert false == serialize(:boolean, false)
    end

    it "can be parsed from a boolean" do
      assert {:ok, true} == parse(:boolean, true)
      assert {:ok, false} == parse(:boolean, false)
    end

    it "cannot be parsed from a number" do
      assert :error == parse(:boolean, 0)
      assert :error == parse(:boolean, 0.0)
    end

    it "cannot be parsed from a binary" do
      assert :error == parse(:boolean, "true")
      assert :error == parse(:boolean, "false")
    end
  end

  describe ":utc_datetime" do
    it "serializes as an ISO8601 date and time string with UTC timezone marker" do
      assert "2017-01-27T20:31:55Z" == serialize(:utc_datetime, @utc_datetime)
    end

    it "can be parsed from an ISO8601 date and time string including timezone" do
      assert {:ok, @utc_datetime} == parse(:utc_datetime, "2017-01-27T20:31:55Z")
      assert {:ok, @utc_datetime} == parse(:utc_datetime, "2017-01-27 20:31:55Z")
    end

    it "cannot be parsed without UTC timezone marker" do
      assert :error == parse(:utc_datetime, "2017-01-27T20:31:55")
      assert :error == parse(:utc_datetime, "2017-01-27 20:31:55")
    end

    it "cannot be parsed when date or time is missing" do
      assert :error == parse(:utc_datetime, "2017-01-27")
      assert :error == parse(:utc_datetime, "20:31:55")
    end

    it "cannot be parsed from a binary not formatted according to ISO8601" do
      assert :error == parse(:utc_datetime, "abc123")
      assert :error == parse(:utc_datetime, "01/25/2017 20:31:55")
      assert :error == parse(:utc_datetime, "2017-15-42T31:71:95Z")
    end

    it "cannot be parsed from a number" do
      assert :error == parse(:utc_datetime, 0)
      assert :error == parse(:utc_datetime, 0.0)
    end

    it "cannot be parsed from a boolean" do
      assert :error == parse(:utc_datetime, true)
      assert :error == parse(:utc_datetime, false)
    end
  end

  describe ":datetime" do
    it "serializes as an ISO8601 date and time string" do
      assert "2017-01-27T20:31:55" == serialize(:datetime, @datetime)
    end

    it "can be parsed from an ISO8601 date and time string" do
      assert {:ok, @datetime} == parse(:datetime, "2017-01-27T20:31:55Z")
      assert {:ok, @datetime} == parse(:datetime, "2017-01-27 20:31:55Z")
      assert {:ok, @datetime} == parse(:datetime, "2017-01-27 20:31:55")
    end

    it "cannot be parsed when date or time is missing" do
      assert :error == parse(:datetime, "2017-01-27")
      assert :error == parse(:datetime, "20:31:55")
    end

    it "cannot be parsed from a binary not formatted according to ISO8601" do
      assert :error == parse(:datetime, "abc123")
      assert :error == parse(:datetime, "01/25/2017 20:31:55")
      assert :error == parse(:datetime, "2017-15-42T31:71:95")
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
end
