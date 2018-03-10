defmodule Absinthe.Schema.Rule.TypeNamesAreValidTest do
  use Absinthe.Case, async: true

  test "Trying to compile a schema with invalid type references fails" do
    assert_raise Absinthe.Schema.Error, fn ->
      load_schema("bad_types_schema")
    end
  end
end
