defmodule Absinthe.Fixtures.SchemaWithDuplicateIdentifiers do
  use Absinthe.Schema

  query do
    # Query type must exist
  end

  object :person do
    description "A person"
    field :name, :string
  end

  object :person, name: "APersonToo" do
    description "A person"
    field :name, :string
  end
end
