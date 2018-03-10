defmodule Absinthe.Adapter.LanguageConventionsTest do
  use Absinthe.Case, async: true

  alias Absinthe.Adapter.LanguageConventions

  describe "to_internal_name/2" do
    test "converts external camelcase field names to underscore" do
      assert "foo_bar" = LanguageConventions.to_internal_name("fooBar", :field)
    end

    test "converts external camelcase variable names to underscore" do
      assert "foo_bar" = LanguageConventions.to_internal_name("fooBar", :variable)
    end
  end

  describe "to_external_name/2" do
    test "converts internal underscored field names to camelcase external field names" do
      assert "fooBar" = LanguageConventions.to_external_name("foo_bar", :field)
    end

    test "converts internal underscored variable names to camelcase external variable names" do
      assert "fooBar" = LanguageConventions.to_external_name("foo_bar", :variable)
    end
  end
end
