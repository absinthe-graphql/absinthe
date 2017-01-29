defmodule ValidSchema do
  use Absinthe.Schema

  object :person do

    query do
      #Query type must exist
    end

    description "A person"
    field :name, :string
  end

end
