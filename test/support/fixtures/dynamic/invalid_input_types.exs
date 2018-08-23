defmodule Absinthe.Fixtures.InvalidOutputTypesSchema do
  use Absinthe.Schema

  object :user do
  end

  input_object :foo do
    field :blah, :user
  end

  query do
    field :foo, :user do
      arg :foo, :foo
    end
  end
end
