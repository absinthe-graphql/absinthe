defmodule BadInterfaceSchema do
  use Absinthe.Schema

  query [
    fields: [
      foo: [type: :foo],
      quux: [type: :quux],
      spam: [type: :spam]
    ]
  ]

  object :foo, [
    fields: [
      not_name: [type: :string]
    ],
    interfaces: [:named],
    is_type_of: fn _ -> true end
  ]

  object :quux, [
    fields: [
      not_name: [type: :string]
    ],
    interfaces: [:foo],
    is_type_of: fn
      _ ->
        true
    end
  ]

   object :spam, [
     fields: [
       name: [type: :string]
     ],
     interfaces: [:named]
   ]

   interface :named, [
     fields: [
       name: [type: :string]
     ]
   ]

end
