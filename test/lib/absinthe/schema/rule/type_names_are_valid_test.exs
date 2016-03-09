defmodule Absinthe.Schema.Rule.TypeNamesAreValidTest do
  use ExUnit.Case, async: true

  test "Trying to compile a schema with invalid type references fails" do
    assert_raise Absinthe.Schema.Error, fn ->
      Code.load_file("test/support/schemas/bad_types_schema.exs")
    end
  end

end
