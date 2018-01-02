defmodule Absinthe.TypeTest do
  use Absinthe.Case, async: true

  alias Absinthe.Type

  context "absinthe_types" do

    context "when a function is tagged as defining a type" do

      context "without a different identifier" do

        it 'includes a defined entry' do
          assert %Type.Object{name: "Item"} = FooBarSchema.__absinthe_type__(:item)
        end

        test "that defines its own name" do
          assert %Type.Object{name: "NonFictionBook"} = FooBarSchema.__absinthe_type__(:book)
        end

        test "that uses a name derived from the identifier" do
          assert %Type.Object{name: "Item"} = FooBarSchema.__absinthe_type__(:item)
        end

      end

      context "with a different identifier" do

        it 'includes a defined entry' do
          assert %Type.Object{name: "Author"} = FooBarSchema.__absinthe_type__(:author)
        end

      end

    end

    test "defines a query type" do
      assert ContactSchema.__absinthe_type__(:query).name == "RootQueryType"
    end

    test "defines a mutation type" do
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


  context ".meta/1" do

    context "when no metadata is defined" do
      test "returns an empty map" do
        assert Type.meta(@without_meta) == %{}
      end
    end

    context "when metadata is defined" do
      test "returns the metadata as a map" do
        assert Type.meta(@with_meta) == %{foo: "bar"}
      end
    end

  end

  context ".meta/2" do

    context "when no metadata field is defined" do
      test "returns nil" do
        assert Type.meta(@without_meta, :bar) == nil
      end
    end

    context "when the requested metadata field is not defined" do
      test "returns nil" do
        assert Type.meta(@with_meta, :bar) == nil
      end
    end


    context "when the metadata is defined" do
      test "returns the value" do
        assert Type.meta(@with_meta, :foo) == "bar"
      end
    end

  end

end
