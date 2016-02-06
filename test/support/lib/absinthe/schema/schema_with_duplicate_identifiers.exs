defmodule SchemaWithDuplicateIdentifiers do
  use Absinthe.Schema

  @doc "A person"
  object :person, [
    fields: [
      name: [type: :string]
    ]
  ]

  @doc "A person"
  object [person: "APersonToo]"], [
    fields: [
      name: [type: :string]
    ]
  ]
end
