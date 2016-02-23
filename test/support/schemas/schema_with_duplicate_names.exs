defmodule SchemaWithDuplicateNames do
  use Absinthe.Schema

  @desc "A person"
  object :person do
    field :name, :string
  end

  @desc "A person"
  object :another_person, name: "Person" do
    field :type, :string
  end

end
