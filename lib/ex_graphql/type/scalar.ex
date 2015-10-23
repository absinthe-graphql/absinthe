defmodule ExGraphQL.Type.Scalar do
  alias ExGraphQL.Type

  @type t :: %{
    name: binary,
    description: binary,
    serialize: (any -> value_t),
    parse_value: nil | (any -> value_t),
    parse_literal: nil | (ExGraphQL.Language.t -> value_t)}

  @type value_t :: any

  defstruct name: nil, description: nil, serialize: nil, parse_value: nil, parse_literal: nil

  use ExGraphQL.Type.Creation
  def setup(struct), do: {:ok, struct}

  @graphql_spec "https://facebook.github.io/graphql/#sec-Int"
  @spec integer :: t
  def integer do
    __MODULE__.create!(name: "Int",
                       description: """
                       The `Int` scalar type represents non-fractional signed whole numeric
                       values. Int can represent values between -(2^53 - 1) and 2^53 - 1 since
                       represented in JSON as double-precision floating point numbers specified
                       by [IEEE 754](http://en.wikipedia.org/wiki/IEEE_floating_point).
                       """ |> String.replace("\n", " "),
                       serialize: &coerce_int/1,
                       parse_value: &coerce_int/1,
                       parse_literal: node_parser([ExGraphQL.Language.IntValue], &coerce_int/1))
  end

  @graphql_spec "https://facebook.github.io/graphql/#sec-Float"
  @spec float :: t
  def float do
    __MODULE__.create!(name: "Float",
                       description: """
                       The `Float` scalar type represents signed double-precision fractional
                       values as specified by
                       [IEEE 754](http://en.wikipedia.org/wiki/IEEE_floating_point).
                       """ |> String.replace("\n", " "),
                       serialize: &coerce_float/1,
                       parse_value: &coerce_float/1,
                       parse_literal: node_parser([ExGraphQL.Language.IntValue,
                                                   ExGraphQL.Language.FloatValue], &coerce_float/1))
  end

  @graphql_spec "https://facebook.github.io/graphql/#sec-String"
  @spec string :: t
  def string do
    __MODULE__.create!(name: "String",
                       description: """
                       The `String` scalar type represents textual data, represented as UTF-8
                       character sequences. The String type is most often used by GraphQL to
                       represent free-form human-readable text.
                       """ |> String.replace("\n", " "),
                       serialize: &to_string/1,
                       parse_value: &to_string/1,
                       parse_literal: node_parser([ExGraphQL.Language.StringValue], &to_string/1))
  end

  @graphql_spec "https://facebook.github.io/graphql/#sec-ID"
  @spec id :: t
  def id do
    __MODULE__.create!(name: "ID",
                       description: """
                       The `ID` scalar type represents a unique identifier, often used to
                       refetch an object or as key for a cache. The ID type appears in a JSON
                       response as a String; however, it is not intended to be human-readable.
                       When expected as an input type, any string (such as `"4"`) or integer
                       (such as `4`) input value will be accepted as an ID.
                       """ |> String.replace("\n", " "),
                       serialize: &to_string/1,
                       parse_value: &to_string/1,
                       parse_literal: node_parser([ExGraphQL.Language.IntValue,
                                                   ExGraphQL.Language.StringValue], &(&1)))
  end

  @graphql_spec "https://facebook.github.io/graphql/#sec-Boolean"
  @spec boolean :: t
  def boolean do
    __MODULE__.create!(name: "Boolean",
                       description: """
                       The `Boolean` scalar type represents `true` or `false`.
                       """ |> String.replace("\n", " "),
                       serialize: &coerce_boolean/1,
                       parse_value: &coerce_boolean/1,
                       parse_literal: node_parser([ExGraphQL.Language.BooleanValue],
                                                  &coerce_boolean/1))
  end

  # Integers are only safe when between -(2^53 - 1) and 2^53 - 1 due to being
  # encoded in JavaScript and represented in JSON as double-precision floating
  # point numbers, as specified by IEEE 754.
  @max_int 9007199254740991
  @min_int -9007199254740991

  @spec coerce_int(integer | float | binary) :: integer
  defp coerce_int(value) when is_integer(value) do
    cond do
      value > @max_int -> @max_int
      value < @min_int -> @min_int
      true -> value
    end
  end
  defp coerce_int(value) when is_float(value) do
    value
    |> String.to_integer(10)
    |> coerce_int
  end
  defp coerce_int(value) when is_binary(value) do
    value
    |> String.to_integer(10)
    |> coerce_int
  end

  @spec coerce_float(integer | float | binary) :: float
  defp coerce_float(value) when is_integer(value) do
    value * 1.0
  end
  defp coerce_float(value) when is_float(value) do
    value
  end
  defp coerce_float(value) when is_binary(value) do
    value |> String.to_float
  end

  @spec coerce_boolean(any) :: boolean
  defp coerce_boolean(value) when is_number(value) do
    value > 0
  end
  defp coerce_boolean(value) do
    !!value
  end

  @spec node_parser([atom], (any -> value_t)) :: (any -> nil | value_t)
  defp node_parser(node_types, coercion) do
    fn
      (%{__struct__: node_type, value: value}) -> if Enum.member?(node_types, node_type), do: coercion.(value), else: nil
      (_) -> nil
    end
  end

end
