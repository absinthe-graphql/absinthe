defmodule Absinthe.Fixtures.ObjectTimesSchema do
  use Absinthe.Schema
  use Absinthe.Fixture

  query do
    field :obj_times, :integer do
      arg :input, non_null(:times_input)

      resolve fn
        _, %{input: %{base: base, multiplier: nil}}, _ ->
          {:ok, base}

        _, %{input: %{base: base, multiplier: num}}, _ ->
          {:ok, base * num}
      end
    end
  end

  input_object :times_input do
    field :multiplier, :integer, default_value: 2
    field :base, non_null(:integer)
  end
end
