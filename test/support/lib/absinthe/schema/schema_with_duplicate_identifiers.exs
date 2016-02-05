defmodule SchemaWithDuplicateIdentifiers do
  use Absinthe.Schema.Definition

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
