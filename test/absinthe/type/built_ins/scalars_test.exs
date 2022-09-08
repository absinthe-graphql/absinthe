defmodule Absinthe.Type.BuiltIns.ScalarsTest do
  use Absinthe.Case, async: false

  alias Absinthe.Type

  defmodule TestSchema do
    use Absinthe.Schema

    query do
      field :foo, :string
    end
  end

  @max_ieee_int 9_007_199_254_740_991
  @min_ieee_int -9_007_199_254_740_991

  defp serialize(type, value) do
    TestSchema.__absinthe_type__(type)
    |> Type.Scalar.serialize(value)
  end

  defp parse(type, value) do
    TestSchema.__absinthe_type__(type)
    |> Type.Scalar.parse(value)
  end

  describe ":integer" do
    test "can serialize a valid integer using default non standard Int (IEEE 754)" do
      assert -1 == serialize(:integer, -1)
      assert 0 == serialize(:integer, 0)
      assert 1 == serialize(:integer, 1)
      assert @max_ieee_int == serialize(:integer, @max_ieee_int)
      assert @min_ieee_int == serialize(:integer, @min_ieee_int)
    end

    test "cannot serialize an integer outside boundaries using default non standard Int (IEEE 754)" do
      assert_raise Absinthe.SerializationError, fn ->
        serialize(:integer, @max_ieee_int + 1)
      end

      assert_raise Absinthe.SerializationError, fn ->
        serialize(:integer, @min_ieee_int - 1)
      end
    end

    test "can parse integer using default non standard Int (IEEE 754)" do
      assert {:ok, 0} == parse(:integer, 0)
      assert {:ok, 1} == parse(:integer, 1)
      assert {:ok, -1} == parse(:integer, -1)
      assert {:ok, @max_ieee_int} == parse(:integer, @max_ieee_int)
      assert {:ok, @min_ieee_int} == parse(:integer, @min_ieee_int)
    end

    test "cannot parse integer outside boundaries using default non standard Int (IEEE 754)" do
      assert :error == parse(:integer, @max_ieee_int + 1)
      assert :error == parse(:integer, @min_ieee_int - 1)
    end
  end

  describe ":float" do
    test "serializes as a float" do
      assert 1.0 == serialize(:float, 1.0)
    end

    test "can be parsed from an integer" do
      assert {:ok, 0.0} == parse(:float, 0)
      assert {:ok, 1.0} == parse(:float, 1)
      assert {:ok, -1.0} == parse(:float, -1)
    end

    test "can be parsed from a float" do
      assert {:ok, 0.0} == parse(:float, 0.0)
      assert {:ok, 1.9} == parse(:float, 1.9)
      assert {:ok, -1.9} == parse(:float, -1.9)
    end

    test "cannot be parsed from a binary" do
      assert :error == parse(:float, "")
      assert :error == parse(:float, "0.0")
    end
  end

  describe ":string" do
    test "serializes as a string" do
      assert "" == serialize(:string, "")
      assert "string" == serialize(:string, "string")
    end

    test "can be parsed from a binary" do
      assert {:ok, ""} == parse(:string, "")
      assert {:ok, "string"} == parse(:string, "string")
    end

    test "cannot be parsed from an integer" do
      assert :error == parse(:string, 0)
    end

    test "cannot be parsed from a float" do
      assert :error == parse(:string, 1.9)
    end
  end

  describe ":id" do
    test "serializes as a string" do
      assert "1" == serialize(:id, 1)
      assert "1" == serialize(:id, "1")
    end

    test "can be parsed from a binary" do
      assert {:ok, ""} == parse(:id, "")
      assert {:ok, "abc123"} == parse(:id, "abc123")
    end

    test "can be parsed from an integer" do
      assert {:ok, "0"} == parse(:id, 0)
      assert {:ok, Integer.to_string(@max_ieee_int)} == parse(:id, @max_ieee_int)
      assert {:ok, Integer.to_string(@min_ieee_int)} == parse(:id, @min_ieee_int)
    end

    test "cannot be parsed from a float" do
      assert :error == parse(:id, 1.9)
    end
  end

  describe ":boolean" do
    test "serializes as a boolean" do
      assert true == serialize(:boolean, true)
      assert false == serialize(:boolean, false)
    end

    test "can be parsed from a boolean" do
      assert {:ok, true} == parse(:boolean, true)
      assert {:ok, false} == parse(:boolean, false)
    end

    test "cannot be parsed from a number" do
      assert :error == parse(:boolean, 0)
      assert :error == parse(:boolean, 0.0)
    end

    test "cannot be parsed from a binary" do
      assert :error == parse(:boolean, "true")
      assert :error == parse(:boolean, "false")
    end
  end
end
