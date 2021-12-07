defmodule Absinthe.Type.BuiltIns.ScalarsTest do
  use Absinthe.Case, async: false

  alias Absinthe.Type

  setup do
    previous_use_legacy_non_compliant_int_scalar_type =
      Application.get_env(
        :absinthe,
        :use_legacy_non_compliant_int_scalar_type,
        :not_configured
      )

    on_exit(fn ->
      if previous_use_legacy_non_compliant_int_scalar_type != :not_configured do
        Application.put_env(
          :absinthe,
          :use_legacy_non_compliant_int_scalar_type,
          previous_use_legacy_non_compliant_int_scalar_type
        )
      end
    end)
  end

  setup_all do
    prevous_compiler_options = Code.compiler_options()

    on_exit(fn ->
      recompile(Absinthe.Type.BuiltIns.Scalars)
      Code.compiler_options(prevous_compiler_options)
    end)
  end

  defmodule TestSchema do
    use Absinthe.Schema

    query do
      # Query type must exist
    end
  end

  @max_graphql_int 2_147_483_647
  @min_graphql_int -2_147_483_648

  @max_ieee_int 9_007_199_254_740_991
  @min_ieee_int -9_007_199_254_740_991

  defp recompile(module) do
    Code.compiler_options(ignore_module_conflict: true)

    [{module, _binary}] =
      module.module_info(:compile)[:source]
      |> List.to_string()
      |> Code.compile_file()

    {:recompiled, module}
  end

  defp serialize(type, value) do
    TestSchema.__absinthe_type__(type)
    |> Type.Scalar.serialize(value)
  end

  defp parse(type, value) do
    TestSchema.__absinthe_type__(type)
    |> Type.Scalar.parse(value)
  end

  describe ":integer" do
    test "can serilize a valid integer using default IEEE 754 Int config" do
      Application.delete_env(:absinthe, :use_legacy_non_compliant_int_scalar_type)
      recompile(Absinthe.Type.BuiltIns.Scalars)

      assert -1 == serialize(:integer, -1)
      assert 0 == serialize(:integer, 0)
      assert 1 == serialize(:integer, 1)
      assert @max_ieee_int == serialize(:integer, @max_ieee_int)
      assert @min_ieee_int == serialize(:integer, @min_ieee_int)
    end

    test "can serilize a valid integer using explicitly defined IEEE 754 Int config" do
      Application.put_env(:absinthe, :use_legacy_non_compliant_int_scalar_type, true)
      recompile(Absinthe.Type.BuiltIns.Scalars)

      assert -1 == serialize(:integer, -1)
      assert 0 == serialize(:integer, 0)
      assert 1 == serialize(:integer, 1)
      assert @max_ieee_int == serialize(:integer, @max_ieee_int)
      assert @min_ieee_int == serialize(:integer, @min_ieee_int)
    end

    test "can serilize a valid integer using GraphQl compliant Int config" do
      Application.put_env(:absinthe, :use_legacy_non_compliant_int_scalar_type, false)
      recompile(Absinthe.Type.BuiltIns.Scalars)

      assert -1 == serialize(:integer, -1)
      assert 0 == serialize(:integer, 0)
      assert 1 == serialize(:integer, 1)
      assert @max_graphql_int == serialize(:integer, @max_graphql_int)
      assert @min_graphql_int == serialize(:integer, @min_graphql_int)
    end

    test "cannot serilize an integer outside boundaries using default IEEE 754 Int config" do
      Application.delete_env(:absinthe, :use_legacy_non_compliant_int_scalar_type)
      recompile(Absinthe.Type.BuiltIns.Scalars)

      assert_raise Absinthe.SerializationError, fn ->
        serialize(:integer, @max_ieee_int + 1)
      end

      assert_raise Absinthe.SerializationError, fn ->
        serialize(:integer, @min_ieee_int - 1)
      end
    end

    test "cannot serilize an integer outside boundaries using explicitly defined IEEE 754 Int config" do
      Application.put_env(:absinthe, :use_legacy_non_compliant_int_scalar_type, true)
      recompile(Absinthe.Type.BuiltIns.Scalars)

      assert_raise Absinthe.SerializationError, fn ->
        serialize(:integer, @max_ieee_int + 1)
      end

      assert_raise Absinthe.SerializationError, fn ->
        serialize(:integer, @min_ieee_int - 1)
      end
    end

    test "cannot serilize an integer outside boundaries using GraphQl compliant Int config" do
      Application.put_env(:absinthe, :use_legacy_non_compliant_int_scalar_type, false)
      recompile(Absinthe.Type.BuiltIns.Scalars)

      assert_raise Absinthe.SerializationError, fn ->
        serialize(:integer, @max_graphql_int + 1)
      end

      assert_raise Absinthe.SerializationError, fn ->
        serialize(:integer, @min_graphql_int - 1)
      end
    end

    test "can parse integer using default IEEE 754 Int config" do
      Application.delete_env(:absinthe, :use_legacy_non_compliant_int_scalar_type)
      recompile(Absinthe.Type.BuiltIns.Scalars)

      assert {:ok, 0} == parse(:integer, 0)
      assert {:ok, 1} == parse(:integer, 1)
      assert {:ok, -1} == parse(:integer, -1)
      assert {:ok, @max_ieee_int} == parse(:integer, @max_ieee_int)
      assert {:ok, @min_ieee_int} == parse(:integer, @min_ieee_int)
    end

    test "cannot parse integer outside boundaries using default IEEE 754 Int config" do
      Application.delete_env(:absinthe, :use_legacy_non_compliant_int_scalar_type)
      recompile(Absinthe.Type.BuiltIns.Scalars)

      assert :error == parse(:integer, @max_ieee_int + 1)
      assert :error == parse(:integer, @min_ieee_int - 1)
    end

    test "can parse integer using explicitly defined IEEE 754 Int config" do
      Application.put_env(:absinthe, :use_legacy_non_compliant_int_scalar_type, true)
      recompile(Absinthe.Type.BuiltIns.Scalars)

      assert {:ok, 0} == parse(:integer, 0)
      assert {:ok, 1} == parse(:integer, 1)
      assert {:ok, -1} == parse(:integer, -1)
      assert {:ok, @max_ieee_int} == parse(:integer, @max_ieee_int)
      assert {:ok, @min_ieee_int} == parse(:integer, @min_ieee_int)
    end

    test "cannot parse integer outside boundaries using explicitly defined IEEE 754 Int config" do
      Application.put_env(:absinthe, :use_legacy_non_compliant_int_scalar_type, true)
      recompile(Absinthe.Type.BuiltIns.Scalars)

      assert :error == parse(:integer, @max_ieee_int + 1)
      assert :error == parse(:integer, @min_ieee_int - 1)
    end

    test "can parse integer using GraphQl compliant Int config" do
      Application.put_env(:absinthe, :use_legacy_non_compliant_int_scalar_type, false)
      recompile(Absinthe.Type.BuiltIns.Scalars)

      assert {:ok, 0} == parse(:integer, 0)
      assert {:ok, 1} == parse(:integer, 1)
      assert {:ok, -1} == parse(:integer, -1)
      assert {:ok, @max_graphql_int} == parse(:integer, @max_graphql_int)
      assert {:ok, @min_graphql_int} == parse(:integer, @min_graphql_int)
    end

    test "cannot parse integer outside boundaries using GraphQl compliant Int config" do
      Application.put_env(:absinthe, :use_legacy_non_compliant_int_scalar_type, false)
      recompile(Absinthe.Type.BuiltIns.Scalars)

      assert :error == parse(:integer, @max_graphql_int + 1)
      assert :error == parse(:integer, @min_graphql_int - 1)
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
