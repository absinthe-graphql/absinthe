defmodule Absinthe.Adapter.StrictLanguageConventionsTest do
  use Absinthe.Case, async: true

  alias Absinthe.Adapter.StrictLanguageConventions

  describe "to_internal_name/2" do
    test "converts external camelcase directive names to underscore" do
      assert "foo_bar" = StrictLanguageConventions.to_internal_name("fooBar", :directive)
    end

    test "converts external camelcase field names to underscore" do
      assert "foo_bar" = StrictLanguageConventions.to_internal_name("fooBar", :field)
    end

    test "converts external camelcase variable names to underscore" do
      assert "foo_bar" = StrictLanguageConventions.to_internal_name("fooBar", :variable)
    end

    test "nullifies external field names that do not match internal name" do
      assert is_nil(StrictLanguageConventions.to_internal_name("foo_bar", :field))
      assert is_nil(StrictLanguageConventions.to_internal_name("FooBar", :field))
      assert is_nil(StrictLanguageConventions.to_internal_name("FOO_BAR", :field))
    end
  end

  describe "to_external_name/2" do
    test "converts internal underscored field names to camelcase external field names" do
      assert "fooBar" = StrictLanguageConventions.to_external_name("foo_bar", :field)
    end

    test "converts internal underscored variable names to camelcase external variable names" do
      assert "fooBar" = StrictLanguageConventions.to_external_name("foo_bar", :variable)
    end
  end
end
