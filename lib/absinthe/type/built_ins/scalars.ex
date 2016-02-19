defmodule Absinthe.Type.BuiltIns.Scalars do
  alias Absinthe.Type.Scalar
  alias Absinthe.Flag
  use Absinthe.Schema.Notation

  @doc """
  The `Int` scalar type represents non-fractional signed whole numeric
  values. Int can represent values between -(2^53 - 1) and 2^53 - 1 since
  represented in JSON as double-precision floating point numbers specified
  by [IEEE 754](http://en.wikipedia.org/wiki/IEEE_floating_point).
  """
  scalar :integer, name: "Int", serialize: &(&1), parse: parse_with([Absinthe.Language.IntValue], &parse_int/1)

  @doc """
  The `Float` scalar type represents signed double-precision fractional
  values as specified by
  [IEEE 754](http://en.wikipedia.org/wiki/IEEE_floating_point).
  """

  scalar :float do
    serialize &(&1)
    parse parse_with([Absinthe.Language.IntValue,
                      Absinthe.Language.FloatValue], &parse_float/1)
  end


  @doc """
  The `String` scalar type represents textual data, represented as UTF-8
  character sequences. The String type is most often used by GraphQL to
  represent free-form human-readable text.
  """
  scalar :string do
    serialize &to_string/1
    parse parse_with([Absinthe.Language.StringValue], &parse_string/1)
  end

  @doc """
  The `ID` scalar type represents a unique identifier, often used to
  refetch an object or as key for a cache. The ID type appears in a JSON
  response as a String; however, it is not intended to be human-readable.
  When expected as an input type, any string (such as `"4"`) or integer
  (such as `4`) input value will be accepted as an ID.
  """
  scalar :id, name: "ID" do
    serialize &to_string/1
    parse parse_with([Absinthe.Language.IntValue,
                       Absinthe.Language.StringValue], &parse_string/1)
  end

  @doc """
  The `Boolean` scalar type represents `true` or `false`.
  """
  scalar :boolean do
    serialize &(&1)
    parse parse_with([Absinthe.Language.BooleanValue], &parse_boolean/1)
  end

  # Integers are only safe when between -(2^53 - 1) and 2^53 - 1 due to being
  # encoded in JavaScript and represented in JSON as double-precision floating
  # point numbers, as specified by IEEE 754.
  @max_int 9007199254740991
  @min_int -9007199254740991

  @spec parse_int(integer | float | binary) :: {:ok, integer} | :error
  defp parse_int(value) when is_integer(value) do
    cond do
      value > @max_int -> @max_int
      value < @min_int -> @min_int
      true -> value
    end
    |> Flag.as(:ok)
  end
  defp parse_int(value) when is_float(value) do
    with {result, _} <- Integer.parse(String.to_integer(value, 10)) do
      parse_int(result)
    end
  end
  defp parse_int(value) when is_binary(value) do
    with {result, _} <- Integer.parse(value) do
      parse_int(result)
    end
  end

  @spec parse_float(integer | float | binary) :: {:ok, float} | :error
  defp parse_float(value) when is_integer(value) do
    {:ok, value * 1.0}
  end
  defp parse_float(value) when is_float(value) do
    {:ok, value}
  end
  defp parse_float(value) when is_binary(value) do
    with {value, _} <- Float.parse(value), do: {:ok, value}
  end
  defp parse_float(_value) do
    :error
  end

  @spec parse_string(any) :: {:ok, binary} | :error
  defp parse_string(value) do
    try do
      {:ok, to_string(value)}
    rescue
      Protocol.UndefinedError -> :error
    end
  end

  @spec parse_boolean(any) :: {:ok, boolean} | :error
  defp parse_boolean(value) when is_number(value) do
    {:ok, value > 0}
  end
  defp parse_boolean(value) do
    {:ok, !!value}
  end

  # Parse, supporting pulling values out of AST nodes
  defmacrop parse_with(node_types, coercion) do
    quote do
      fn
        %{value: value} = node ->
          if Enum.is_member?(unquote(node_types), node) do
            unquote(coercion).(value)
         else
            nil
         end
       other ->
          unquote(coercion).(other)
      end
    end
  end

end
