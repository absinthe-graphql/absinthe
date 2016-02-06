defmodule SchemaWithDuplicateNames do
  use Absinthe.Schema

  @doc "A person"
  object :person, [
    fields: [
      name: [type: :string]
    ]
  ]

  @doc "A person"
  object [another_person: "Person"], [
    fields: [
      name: [type: :string]
    ]
  ]
end
