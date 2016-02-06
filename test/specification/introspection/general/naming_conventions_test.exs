defmodule Absinthe.Specification.Introspection.General.NamingConventionsTest do
  use ExSpec, async: true

  describe "custom types" do


    @standard "Must not define any types, fields, arguments, or any other type system artifact with two leading underscores."

    it "cannot start with the `__` prefix" do
      err = assert_raise Absinthe.Schema.Error, fn ->
        Code.require_file("test/support/specification/introspection/general/prefix_schema.exs")
      end
      assert Enum.find(err.problems, fn
        problem ->
          match?(%{name: :res_type_name, data: "__MyThing"}, problem)
      end)
      assert Enum.find(err.problems, fn
        problem ->
          match?(%{name: :res_type_ident, data: :__mything}, problem)
      end)
      assert Enum.find(err.problems, fn
        problem ->
          match?(%{name: :res_field_name, data: "__mything"}, problem)
      end)
      assert Enum.find(err.problems, fn
        problem ->
          match?(%{name: :res_arg_name, data: "__mything"}, problem)
      end)
    end

  end

end
