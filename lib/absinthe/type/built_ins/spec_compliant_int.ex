defmodule Absinthe.Type.BuiltIns.SpecCompliantInt do
  use Absinthe.Schema.Notation

  @moduledoc false

  scalar :integer, name: "Int" do
    description """
    The `Int` scalar type represents non-fractional signed whole numeric
    values between `-2^31` and `2^31 - 1`, as outlined in the
    [GraphQl spec](https://spec.graphql.org/October2021/#sec-Int).
    """

    serialize &__MODULE__.serialize_int/1
    parse parse_with([Absinthe.Blueprint.Input.Integer], &parse_int/1)
  end

  @min_int -2_147_483_648
  @max_int 2_147_483_647

  def serialize_int(value) when is_integer(value) and value >= @min_int and value <= @max_int do
    value
  end

  defp parse_int(value) when is_integer(value) and value >= @min_int and value <= @max_int do
    {:ok, value}
  end

  defp parse_int(_) do
    {:error, "Expected an integer from `-2^31` to `2^31 - 1` (inclusive)"}
  end

  # Parse, supporting pulling values out of blueprint Input nodes
  defp parse_with(node_types, coercion) do
    fn
      %{__struct__: str, value: value} ->
        if Enum.member?(node_types, str) do
          coercion.(value)
        else
          :error
        end

      %Absinthe.Blueprint.Input.Null{} ->
        {:ok, nil}

      other ->
        coercion.(other)
    end
  end
end
