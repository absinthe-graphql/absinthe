defmodule Absinthe.Fixtures.SchemaWithDuplicateNames do
  use Absinthe.Schema

  query do
    # Query type must exist
  end

  object :person do
    description "A person"
    field :name, :string
  end

  object :another_person, name: "Person" do
    description "A person"
    field :type, :string
  end
end
