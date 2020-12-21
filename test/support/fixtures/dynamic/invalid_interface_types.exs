defmodule Absinthe.Fixtures.InvalidInterfaceTypes do
  use Absinthe.Schema

  object :user do
    field :name, non_null(:string)
    interface :named

    is_type_of fn _ ->
      true
    end
  end

  object :foo do
    field :name, :string
    interface :named

    is_type_of fn _ ->
      true
    end
  end

  interface :named do
    field :name, non_null(:string)
  end

  query do
  end
end
