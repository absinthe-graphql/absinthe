defmodule SchemaWithDuplicateNames do
  use Absinthe.Schema

  object :person do
    description "A person"
    field :name, :string
  end

  object :another_person, name: "Person" do
    description "A person"
    field :type, :string
  end

end
