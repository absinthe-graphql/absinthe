defmodule Absinthe.Fixtures.InvalidInputTypesSchema do
  use Absinthe.Schema

  object :user do
    field :name, :string
  end

  input_object :input do
    field :foo, :string
  end

  object :bad_object do
    field :blah, :input
  end

  query do
    field :foo, :user do
      arg :invalid_arg, :user
    end
  end
end
