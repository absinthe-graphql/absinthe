defmodule Absinthe.Fixtures.TimesSchema do
  use Absinthe.Schema
  use Absinthe.Fixture

  query do
    field :times, :integer do
      arg :multiplier, :integer, default_value: 2
      arg :base, non_null(:integer)

      resolve fn
        _, %{base: base, multiplier: nil}, _ ->
          {:ok, base}

        _, %{base: base, multiplier: num}, _ ->
          {:ok, base * num}

        _, %{base: _}, _ ->
          {:error, "Didn't get any multiplier"}
      end
    end
  end
end
