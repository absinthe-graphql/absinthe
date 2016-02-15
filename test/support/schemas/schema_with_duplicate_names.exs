defmodule SchemaWithDuplicateNames do
  use Absinthe.Schema

  @doc "A person"
  object :person do
    field :name, :string
  end

  @doc "A person"
  object :another_person, name: "Person" do
    field :type, :string
  end

end
