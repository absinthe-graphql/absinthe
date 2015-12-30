defmodule Absinthe.IdTestSchema do
  use Absinthe.Schema
  alias Absinthe.Type

  # Example data
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
      description: "An item",
      fields: fields(
        id: [type: :id],
        name: [type: :string]
      )
    }
  end

end
