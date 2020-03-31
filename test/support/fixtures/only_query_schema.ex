defmodule Absinthe.Fixtures.OnlyQuerySchema do
  use Absinthe.Schema
  use Absinthe.Fixture

  query do
    field :hello, :string do
      resolve fn _, _ -> {:ok, "world"} end
    end
  end
end
