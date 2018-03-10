defmodule Absinthe.TypeTest do
  use Absinthe.Case, async: true

  alias Absinthe.Type

  defmodule BasicSchema do
    use Absinthe.Schema

    @items %{
      "foo" => %{id: "foo", name: "Foo"},
      "bar" => %{id: "bar", name: "Bar"}
    }

    query do
      field :item,
        type: :item,
        args: [
          id: [type: non_null(:id)]
        ],
        resolve: fn %{id: item_id}, _ ->
          {:ok, @items[item_id]}
        end
    end

    object :item do
      description "A Basic Type"

      field :id, :id
      field :name, :string
    end

    object :author do
      description "An author"

      field :id, :id
      field :first_name, :string
      field :last_name, :string
      field :books, list_of(:book)
    end

    object :book, name: "NonFictionBook" do
      description "A Book"

      field :id, :id
      field :title, :string
      field :isbn, :string
      field :authors, list_of(:author)
    end
  end

  test "definition with custom name" do
    assert %Type.Object{name: "NonFictionBook"} = BasicSchema.__absinthe_type__(:book)
  end

  test "that uses a name derived from the identifier" do
    assert %Type.Object{name: "Item"} = BasicSchema.__absinthe_type__(:item)
  end

  test "root query type definition" do
    assert Absinthe.Fixtures.ContactSchema.__absinthe_type__(:query).name == "RootQueryType"
  end

  test "root mutation type definition" do
    assert Absinthe.Fixtures.ContactSchema.__absinthe_type__(:mutation).name == "RootMutationType"
  end

  defmodule MetadataSchema do
    use Absinthe.Schema

    query do
      # Query type must exist
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
    test "when no metadata is defined, returns an empty map" do
      assert Type.meta(@without_meta) == %{}
    end

    test "when metadata is defined, returns the metadata as a map" do
      assert Type.meta(@with_meta) == %{foo: "bar"}
    end
  end

  describe ".meta/2" do
    test "when no metadata field is defined, returns nil" do
      assert Type.meta(@without_meta, :bar) == nil
    end

    test "when the requested metadata field is not defined, returns nil" do
      assert Type.meta(@with_meta, :bar) == nil
    end

    test "when the metadata is defined, returns the value" do
      assert Type.meta(@with_meta, :foo) == "bar"
    end
  end
end
