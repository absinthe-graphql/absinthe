defmodule FooBarSchema do
  use Absinthe.Schema
  alias Absinthe.Type

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

  @doc "A Basic Type"
  object :item do
    field :id, :id
    field :name, :string
  end

  @doc "An author"
  object :author do
    field :id, :id
    field :first_name, :string
    field :last_name, :string
    field :books, list_of(:book)
  end

  @doc "A Book"
  object :book, "NonFictionBook" do
    field :id, :id
    field :title, :string
    field :isbn, :string
    field :authors, list_of(:author)
  end

end
