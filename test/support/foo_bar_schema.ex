defmodule FooBarSchema do
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
