defmodule ValidSchema do
  use Absinthe.Schema

  @desc "A person"
  object :person do
    field :name, :string
  end

end
