defmodule Absinthe.Type.TypeMapTest do
  use ExSpec, async: true

  alias Absinthe.Type

  describe "schema type map" do

    it "finds custom types" do
      types = Things.schema.types

      assert types[:thing]
      assert types[:input_thing]
    end

    it "includes the types referenced" do
      type_map = FooBarSchema.schema.types
      assert type_map[:string] == Type.Scalar.absinthe_types[:string]
      assert type_map[:id] == Type.Scalar.absinthe_types[:id]
      assert type_map.by_name["String"] == Type.Scalar.absinthe_types[:string]
      assert type_map.by_name["ID"] == Type.Scalar.absinthe_types[:id]
    end

    it "includes built-in types not referenced" do
      type_map = FooBarSchema.schema.types
      assert type_map[:boolean] == Type.Scalar.absinthe_types[:boolean]
    end

  end

end
