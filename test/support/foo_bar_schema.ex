defmodule FooBarSchema do

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
