defmodule SchemaWithDuplicateIdentifiers do
  use Absinthe.Schema

  object :person do
    description "A person"
    field :name, :string
  end

  object :person, name: "APersonToo" do
    description "A person"
    field :name, :string
  end

end
