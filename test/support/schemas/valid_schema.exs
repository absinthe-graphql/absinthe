defmodule ValidSchema do
  use Absinthe.Schema

  @doc "A person"
  object :person, [
    fields: [
      name: [type: :string]
    ]
  ]

end
