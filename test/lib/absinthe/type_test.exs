defmodule Absinthe.TypeTest do
  use Absinthe.Case, async: true

  alias Absinthe.Type

  describe "absinthe_types" do

    describe "when a function is tagged as defining a type" do

      describe "without a different identifier" do

        it 'includes a defined entry' do
          assert %Type.Object{name: "Item"} = FooBarSchema.__absinthe_type__(:item)
        end

        it "that defines its own name" do
          assert %Type.Object{name: "NonFictionBook"} = FooBarSchema.__absinthe_type__(:book)
        end

        it "that uses a name derived from the identifier" do
          assert %Type.Object{name: "Item"} = FooBarSchema.__absinthe_type__(:item)
        end

      end

      describe "with a different identifier" do

        it 'includes a defined entry' do
          assert %Type.Object{name: "Author"} = FooBarSchema.__absinthe_type__(:author)
        end

      end

    end

    it "defines a query type" do
      assert ContactSchema.__absinthe_type__(:query).name == "RootQueryType"
    end

    it "defines a mutation type" do
      assert ContactSchema.__absinthe_type__(:mutation).name == "RootMutationType"
    end

  end

end
