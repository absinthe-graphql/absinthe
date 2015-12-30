defmodule Absinthe.TypeTest do
  use ExSpec, async: true

  alias Absinthe.Type

  defmodule MyApp do

    use Absinthe.Schema

    alias Absinthe.Type

    @items %{
      "foo" => %{id: "foo", name: "Foo"},
      "bar" => %{id: "bar", name: "Bar"}
    }

    def query do
      %Type.Object{
        fields: fields(
          item: [
            type: :item,
            args: args(
              id: [type: non_null(:id)]
            ),
            resolve: fn %{id: item_id}, _ ->
              {:ok, @items[item_id]}
            end
          ]
        )
      }
    end

    @absinthe :type
    def item do
      %Type.Object{
        description: "A Basic Type",
        fields: fields(
          id: [type: :id],
          name: [type: :string]
        )
      }
    end

    @absinthe type: :author
    def person do
      %Type.Object{
        description: "A Person",
        fields: fields(
          id: [type: :id],
          first_name: [type: :string],
          last_name: [type: :string],
          books: [type: list_of(:book)]
        )
      }
    end

    @absinthe :type
    def book do
      %Type.Object{
        name: "NonFictionBook",
        description: "A Book",
        fields: fields(
          id: [type: :id],
          title: [type: :string],
          isbn: [type: :string],
          authors: [type: list_of(:author)]
        )
      }
    end

  end

  describe "type_map" do

    it "includes the types referenced" do
      type_map = MyApp.schema.types
      assert type_map[:string] == Type.Scalar.absinthe_types[:string]
      assert type_map[:id] == Type.Scalar.absinthe_types[:id]
    end

    it "includes built-in types not referenced" do
      type_map = MyApp.schema.types
      assert type_map[:boolean] == Type.Scalar.absinthe_types[:boolean]
    end

  end

  describe "absinthe_types" do

    describe "when a function is tagged as defining a type" do

      describe "without a different identifier" do

        it 'includes a defined entry' do
          assert %Type.Object{name: "Item"} = Absinthe.TypeTest.MyApp.absinthe_types[:item]
        end

        describe "that defines its own name" do
          assert %Type.Object{name: "NonFictionBook"} = Absinthe.TypeTest.MyApp.absinthe_types[:book]
        end

        describe "that uses a name derived from the identifier" do
          assert %Type.Object{name: "Item"} = Absinthe.TypeTest.MyApp.absinthe_types[:item]
        end

      end

      describe "with a different identifier" do

        it 'includes a defined entry' do
          assert %Type.Object{name: "Author"} = Absinthe.TypeTest.MyApp.absinthe_types[:author]
        end

      end

    end

  end

end
