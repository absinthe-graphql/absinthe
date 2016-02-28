defmodule ValidSchema do
  use Absinthe.Schema

  object :person do
    description "A person"
    field :name, :string
  end

end
