defmodule Absinthe.Adapter.LanguageConventionsTest do
  use Absinthe.Case, async: true

  alias Absinthe.Adapter.LanguageConventions

  it "converts external camelcase field names to underscore" do
    assert "foo_bar" = LanguageConventions.to_internal_name("fooBar", :field)
  end
  it "converts external camelcase variable names to underscore" do
    assert "foo_bar" = LanguageConventions.to_internal_name("fooBar", :variable)
  end

  it "converts internal underscored field names to camelcase external field names" do
    assert "fooBar" = LanguageConventions.to_external_name("foo_bar", :field)
  end
  it "converts internal underscored variable names to camelcase external variable names" do
    assert "fooBar" = LanguageConventions.to_external_name("foo_bar", :variable)
  end

end
