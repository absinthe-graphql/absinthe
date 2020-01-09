defmodule HydrateBuiltinsTest do
  use ExUnit.Case, async: true

  defmodule Schema do
    use Absinthe.Schema

    query do
      field :value, :float do
        # intentionally a float
        resolve fn _, _, _ -> {:ok, 1} end
      end
    end

    def hydrate(%Absinthe.Blueprint.Schema.ScalarTypeDefinition{identifier: :float}, _) do
      {:serialize, &__MODULE__.serialize_float/1}
    end

    def hydrate(_, _) do
      []
    end

    def serialize_float(number) when is_number(number) do
      number * 1.0
    end
  end

  test "we can override the builtin scalars" do
    assert {:ok, %{data: %{"value" => 1.0}}} == Absinthe.run("{ value }", Schema)
  end
end
