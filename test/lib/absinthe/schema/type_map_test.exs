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
      assert type_map[:string] == Type.Scalar.__absinthe_info__(:types)[:string]
      assert type_map[:id] == Type.Scalar.__absinthe_info__(:types)[:id]
      assert type_map.by_name["String"] == Type.Scalar.__absinthe_info__(:types)[:string]
      assert type_map.by_name["ID"] == Type.Scalar.__absinthe_info__(:types)[:id]
    end

    it "includes built-in types not referenced" do
      type_map = FooBarSchema.schema.types
      assert type_map[:boolean] == Type.Scalar.__absinthe_info__(:types)[:boolean]
    end

    defmodule Schema do
      use Absinthe.Schema
      alias Absinthe.Type

      def query do
        %Type.Object{
          fields: fields(
            foo: [
              type: :string,
              args: args(
                contact_input: [type: :contact_input]
              )
            ]
          )
        }
      end

      @absinthe :type
      def contact_input do
        %Type.InputObject{
          description: "An input contact",
          fields: fields(
            value: [type: non_null(:string)],
            kind: [type: :phone_or_email]
          )
        }
      end

      @absinthe :type
      def phone_or_email do
        %Type.Enum{
          description: "Either a phone number or email",
          values: values(
            phone: [description: "A phone number", value: "phone"],
            email: [description: "An email address", value: "email"]
          )
        }
      end

    end

    @tag :input
    it "has the type in the typemap" do
      assert Schema.schema.types.by_identifier[:phone_or_email]
    end

  end

end
