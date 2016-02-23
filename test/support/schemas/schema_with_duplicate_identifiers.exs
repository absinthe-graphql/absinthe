defmodule SchemaWithDuplicateIdentifiers do
  use Absinthe.Schema

  @desc "A person"
  object :person do
    field :name, :string
  end

  @desc "A person"
  object :person, name: "APersonToo" do
    field :name, :string
  end

end
