defmodule Absinthe.Adapter.DigitAwareLanguageConventionsTest do
  use Absinthe.Case, async: true

  alias Absinthe.Adapter.DigitAwareLanguageConventions, as: Adapter

  describe "to_internal_name/2" do
    test "converts external camelcase field names to underscore" do
      assert "foo_bar" = Adapter.to_internal_name("fooBar", :field)
    end

    test "converts external camelcase variable names to underscore" do
      assert "foo_bar" = Adapter.to_internal_name("fooBar", :variable)
    end

    test "converts external camelcase directive names to underscore" do
      assert "foo_bar" = Adapter.to_internal_name("fooBar", :directive)
    end

    test "handles nil" do
      assert is_nil(Adapter.to_internal_name(nil, :field))
    end

    test "preserves __ prefix (introspection names)" do
      assert "__type_name" = Adapter.to_internal_name("__typeName", :field)
    end

    test "handles digit boundaries in camelCase names" do
      assert "requires_2fa" = Adapter.to_internal_name("requires2fa", :field)
      assert "work_phone_2" = Adapter.to_internal_name("workPhone2", :field)
      assert "field_2_name" = Adapter.to_internal_name("field2Name", :field)
      assert "address_line_1" = Adapter.to_internal_name("addressLine1", :field)
    end

    test "inserts underscores at digit boundaries even for non-camelCase names" do
      assert "req_1" = Adapter.to_internal_name("req1", :field)
      assert "test_123" = Adapter.to_internal_name("test123", :field)
    end

    test "passes through already-underscored names" do
      assert "foo_bar" = Adapter.to_internal_name("foo_bar", :field)
      assert "requires_2fa" = Adapter.to_internal_name("requires_2fa", :field)
    end
  end

  describe "to_external_name/2" do
    test "converts internal underscored field names to camelcase" do
      assert "fooBar" = Adapter.to_external_name("foo_bar", :field)
    end

    test "converts internal underscored variable names to camelcase" do
      assert "fooBar" = Adapter.to_external_name("foo_bar", :variable)
    end

    test "handles nil" do
      assert is_nil(Adapter.to_external_name(nil, :field))
    end

    test "preserves __ prefix (introspection names)" do
      assert "__typeName" = Adapter.to_external_name("__type_name", :field)
    end

    test "camelizes names with digits" do
      assert "requires2fa" = Adapter.to_external_name("requires_2fa", :field)
      assert "workPhone2" = Adapter.to_external_name("work_phone_2", :field)
      assert "field2Name" = Adapter.to_external_name("field_2_name", :field)
      assert "addressLine1" = Adapter.to_external_name("address_line_1", :field)
    end
  end

  describe "roundtrip" do
    test "to_external then to_internal returns the original name" do
      names = [
        "foo_bar",
        "requires_2fa",
        "work_phone_2",
        "field_2_name",
        "address_line_1",
        "first_name",
        "created_at"
      ]

      for name <- names do
        external = Adapter.to_external_name(name, :field)
        assert name == Adapter.to_internal_name(external, :field),
               "roundtrip failed for #{name}: #{name} -> #{external} -> #{Adapter.to_internal_name(external, :field)}"
      end
    end

    test "to_internal then to_external returns the original camelCase name" do
      names = [
        "fooBar",
        "requires2fa",
        "workPhone2",
        "field2Name",
        "addressLine1",
        "firstName",
        "createdAt"
      ]

      for name <- names do
        internal = Adapter.to_internal_name(name, :field)
        assert name == Adapter.to_external_name(internal, :field),
               "roundtrip failed for #{name}: #{name} -> #{internal} -> #{Adapter.to_external_name(internal, :field)}"
      end
    end
  end
end
