defmodule Absinthe.IdTestSchema do
  use Absinthe.Schema

  # Example data
  @items %{
    "foo" => %{id: "foo", name: "Foo"},
    "bar" => %{id: "bar", name: "Bar"}
  }

  query [
    fields: [
      item: [
        type: :item,
        args: [
          id: [type: non_null(:id)]
        ],
        resolve: fn %{id: item_id}, _ ->
          {:ok, @items[item_id]}
        end
      ]
    ]
  ]

  @doc "An item"
  object :item, [
    fields: [
      id: [type: :id],
      name: [type: :string]
    ]
  ]

end
