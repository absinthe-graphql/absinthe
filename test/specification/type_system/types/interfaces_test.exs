defmodule Specification.TypeSystem.Types.InterfacesTest do
  use ExSpec, async: true
  @moduletag :specification

  @graphql_spec "#sec-Interfaces"

  describe "an object that implements an interface" do

    describe "when it defines those field" do

      defmodule GoodSchema do
        use Absinthe.Schema
        alias Absinthe.Type

        def query do
          %Type.Object{
            fields: fields(
              foo: [type: :foo],
              bar: [type: :bar]
            )
          }
        end

        @absinthe :type
        def foo do
          %Type.Object{
            fields: fields(
              name: [type: :string]
            ),
            interfaces: [:named]
          }
        end

        @absinthe :type
        def bar do
          %Type.Object{
            fields: fields(
              name: [type: :string]
            ),
            interfaces: [:named]
          }
        end

        # NOT USED IN THE SCHEMA
        @absinthe :type
        def baz do
          %Type.Object{
            fields: fields(
              name: [type: :string]
            ),
            interfaces: [:named]
          }
        end

        @absinthe :type
        def named do
          %Type.Interface{
            fields: fields(
              name: [type: :string]
            )
          }
        end
      end

      it "causes no schema errors" do
        assert %{errors: []} = GoodSchema.schema
      end

      it "captures the relationships in the schema" do
        schema = GoodSchema.schema
        assert :foo in schema.interfaces[:named]
        assert :bar in schema.interfaces[:named]
      end

      it "does not captures the relationships not in the schema" do
        schema = GoodSchema.schema
        assert not :baz in schema.interfaces[:named]
      end


    end

    describe "when it doesn't define those fields" do

      defmodule BadSchema do
        use Absinthe.Schema
        alias Absinthe.Type

        def query do
          %Type.Object{
            fields: fields(
              foo: [type: :foo]
            )
          }
        end

        @absinthe :type
        def foo do
          %Type.Object{
            fields: fields(
              not_name: [type: :string]
            ),
            interfaces: [:named]
          }
        end

        @absinthe :type
        def named do
          %Type.Interface{
            fields: fields(
              name: [type: :string]
            )
          }
        end
      end

      it "causes a schema error" do
        assert %{errors: ["The :foo object type does not implement the :named interface type, as declared"]} = BadSchema.schema
      end
    end
  end

end
