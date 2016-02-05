defmodule ValidSchema do
  use Absinthe.Schema.Definition

  @doc "A person"
  object :person, [
    fields: [
      name: [type: :string]
    ]
  ]

end
