defmodule ValidSchema do
  use Absinthe.Schema

  @doc "A person"
  object :person do
    field :name, :string
  end

end
