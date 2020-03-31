defmodule Absinthe.Fixtures.IdTestSchema do
  use Absinthe.Schema
  use Absinthe.Fixture

  # Example data
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
    description "An item"
    field :id, :id
    field :name, :string
  end
end
