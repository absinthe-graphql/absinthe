defmodule Absinthe.Fixtures.ValidSchema do
  use Absinthe.Schema

  query do
    # Query type must exist
  end

  object :person do
    description "A person"
    field :name, :string
  end
end
