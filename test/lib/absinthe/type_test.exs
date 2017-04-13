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

  defmodule MetadataSchema do
    use Absinthe.Schema

    query do
      #Query type must exist
    end

    object :with_meta do
      meta :foo, "bar"
    end

    object :without_meta do
    end

  end

  @with_meta Absinthe.Schema.lookup_type(MetadataSchema, :with_meta)
  @without_meta Absinthe.Schema.lookup_type(MetadataSchema, :without_meta)


  describe ".meta/1" do

    describe "when no metadata is defined" do
      it "returns an empty map" do
        assert Type.meta(@without_meta) == %{}
      end
    end

    describe "when metadata is defined" do
      it "returns the metadata as a map" do
        assert Type.meta(@with_meta) == %{foo: "bar"}
      end
    end

  end

  describe ".meta/2" do

    describe "when no metadata field is defined" do
      it "returns nil" do
        assert Type.meta(@without_meta, :bar) == nil
      end
    end

    describe "when the requested metadata field is not defined" do
      it "returns nil" do
        assert Type.meta(@with_meta, :bar) == nil
      end
    end


    describe "when the metadata is defined" do
      it "returns the value" do
        assert Type.meta(@with_meta, :foo) == "bar"
      end
    end

  end

end
