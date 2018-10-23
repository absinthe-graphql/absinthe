defmodule Absinthe.Schema.Rule.TypeNamesAreValidTest do
  use Absinthe.Case, async: true

  @tag :pending_schema
  test "Trying to compile a schema with invalid type references fails" do
    assert_raise Absinthe.Schema.CompilationError, fn ->
      load_schema("bad_types_schema")
    end
  end
end
