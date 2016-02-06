defmodule FooBarSchema do
  use Absinthe.Schema
  alias Absinthe.Type

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

  @doc "A Basic Type"
  object :item, [
    fields: [
      id: [type: :id],
      name: [type: :string]
    ]
  ]

  @doc "A Person"
  object :person, [
    fields: [
      id: [type: :id],
      first_name: [type: :string],
      last_name: [type: :string],
      books: [type: list_of(:book)]
    ]
  ]

  @doc "A Book"
  object [book: "NonFictionBook"], [
    fields: [
      id: [type: :id],
      title: [type: :string],
      isbn: [type: :string],
      authors: [type: list_of(:author)]
    ]
  ]

end
