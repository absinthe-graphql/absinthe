defmodule Absinthe.Type.BuiltIns.Scalars do
  use Absinthe.Schema.Notation

  @moduledoc false

  @max_int 9_007_199_254_740_991
  @min_int -9_007_199_254_740_991

  scalar :integer, name: "Int" do
    description """
    The `Int` scalar type represents non-fractional signed whole numeric
    values. It is NOT compliant with the GraphQl spec, it can represent
    values between `-(2^53 - 1)` and `2^53 - 1` as specified by
    [IEEE 754](https://en.wikipedia.org/wiki/IEEE_754).
    It is kept here for backwards compatibility, prefer using
    the SpecCompliantInt.
    """

    serialize &__MODULE__.serialize_int/1
    parse parse_with([Absinthe.Blueprint.Input.Integer], &parse_int/1)
  end

  def serialize_int(value) when is_integer(value) and value >= @min_int and value <= @max_int do
    value
  end

  def serialize_int(value) do
    raise Absinthe.SerializationError, """
    Value #{inspect(value)} is not a valid Int.
    """
  end

  scalar :float do
    description """
    The `Float` scalar type represents signed double-precision fractional
    values as specified by
    [IEEE 754](https://en.wikipedia.org/wiki/IEEE_754).
    """

    serialize &__MODULE__.serialize_float/1

    parse parse_with(
            [Absinthe.Blueprint.Input.Integer, Absinthe.Blueprint.Input.Float],
            &parse_float/1
          )
  end

  def serialize_float(n) when is_float(n), do: n
  def serialize_float(n) when is_integer(n), do: n * 1.0

  def serialize_float(n) do
    raise Absinthe.SerializationError, """
    Value #{inspect(n)} is not a valid float
    """
  end

  scalar :string do
    description """
    The `String` scalar type represents textual data, represented as UTF-8
    character sequences. The String type is most often used by GraphQL to
    represent free-form human-readable text.
    """

    serialize &String.Chars.to_string/1
    parse parse_with([Absinthe.Blueprint.Input.String], &parse_string/1)
  end

  scalar :id, name: "ID" do
    description """
    The `ID` scalar type represents a unique identifier, often used to
    refetch an object or as key for a cache. The ID type appears in a JSON
    response as a String; however, it is not intended to be human-readable.
    When expected as an input type, any string (such as `"4"`) or integer
    (such as `4`) input value will be accepted as an ID.
    """

    serialize &to_string/1

    parse parse_with(
            [Absinthe.Blueprint.Input.Integer, Absinthe.Blueprint.Input.String],
            &parse_id/1
          )
  end

  scalar :boolean do
    description """
    The `Boolean` scalar type represents `true` or `false`.
    """

    serialize &__MODULE__.serialize_boolean/1
    parse parse_with([Absinthe.Blueprint.Input.Boolean], &parse_boolean/1)
  end

  def serialize_boolean(true), do: true
  def serialize_boolean(false), do: false

  def serialize_boolean(val) do
    raise Absinthe.SerializationError, """
    Value #{inspect(val)} is not a valid boolean
    """
  end

  @spec parse_int(any) :: {:ok, integer} | :error
  defp parse_int(value) when is_integer(value) and value >= @min_int and value <= @max_int do
    {:ok, value}
  end

  defp parse_int(_) do
    :error
  end

  @spec parse_float(any) :: {:ok, float} | :error
  defp parse_float(value) when is_float(value) do
    {:ok, value}
  end

  defp parse_float(value) when is_integer(value) do
    {:ok, value * 1.0}
  end

  defp parse_float(_) do
    :error
  end

  @spec parse_string(any) :: {:ok, binary} | :error
  defp parse_string(value) when is_binary(value) do
    {:ok, value}
  end

  defp parse_string(_) do
    :error
  end

  @spec parse_id(any) :: {:ok, binary} | :error
  defp parse_id(value) when is_binary(value) do
    {:ok, value}
  end

  defp parse_id(value) when is_integer(value) do
    {:ok, Integer.to_string(value)}
  end

  defp parse_id(_) do
    :error
  end

  @spec parse_boolean(any) :: {:ok, boolean} | :error
  defp parse_boolean(value) when is_boolean(value) do
    {:ok, value}
  end

  defp parse_boolean(_) do
    :error
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
