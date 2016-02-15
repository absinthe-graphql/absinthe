defmodule SchemaWithDuplicateIdentifiers do
  use Absinthe.Schema

  @doc "A person"
  object :person do
    field :name, :string
  end

  @doc "A person"
  object :person, name: "APersonToo" do
    field :name, :string
  end

end
