defmodule Absinthe.Fixtures.InvalidInputTypesSchema do
  use Absinthe.Schema

  object :user do
  end

  input_object :input do
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
