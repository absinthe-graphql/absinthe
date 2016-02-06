defmodule PrefixSchema do

  use Absinthe.Schema

  query [
    fields: [
      __mything: [
        name: "__mything",
        type: :thing,
        args: [
          __myarg: [type: :integer]
        ],
        resolve: fn
          _, _ ->
            {:ok, %{name: "Test"}}
        end
      ]
    ]
  ]

  object [__mything: "__MyThing"], [
    fields: [
      name: [type: :string]
    ]
  ]

end
