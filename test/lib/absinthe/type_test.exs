defmodule Absinthe.TypeTest do
  use ExSpec, async: true

  alias Absinthe.Type

  describe "absinthe_types" do

    describe "when a function is tagged as defining a type" do

      describe "without a different identifier" do

        it 'includes a defined entry' do
          assert %Type.Object{name: "Item"} = FooBarSchema.absinthe_types[:item]
        end

        describe "that defines its own name" do
          assert %Type.Object{name: "NonFictionBook"} = FooBarSchema.absinthe_types[:book]
        end

        describe "that uses a name derived from the identifier" do
          assert %Type.Object{name: "Item"} = FooBarSchema.absinthe_types[:item]
        end

      end

      describe "with a different identifier" do

        it 'includes a defined entry' do
          assert %Type.Object{name: "Author"} = FooBarSchema.absinthe_types[:author]
        end

      end

    end

  end

end
