defmodule Absinthe.Specification.Introspection.GeneralPrinciples.NamingConventionsTest do
  use ExSpec, async: true

  describe "custom types" do

    defmodule PrefixSchema do

      use Absinthe.Schema
      alias Absinthe.Type

      def query do
        %Type.Object{
          fields: fields(
            __mything: [
              type: :thing,
              args: args(
                __myarg: [type: :integer]
              ),
              resolve: fn
                _, _ ->
                  {:ok, %{name: "Test"}}
              end
            ]
          )
        }
      end

      @absinthe :type
      def thing do
        %Type.Object{
          name: "__MyThing",
          fields: fields(
            name: [type: :string]
          )
        }
      end

    end

    @standard "Must not define any types, fields, arguments, or any other type system artifact with two leading underscores."

    it "cannot start with the `__` prefix" do
      errs = [
        "Field `__mything': #{@standard}",
        "Argument `__myarg': #{@standard}",
        "Object `__MyThing': #{@standard}"
      ] |> Enum.sort
      assert {:error, found_errs} = Absinthe.Schema.verify(PrefixSchema)
      assert Enum.sort(found_errs) == errs
    end

  end

end
