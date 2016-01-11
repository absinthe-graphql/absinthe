defmodule Absinthe.Type.Scalar do

  @moduledoc """
  Represents a primitive value.

  GraphQL responses take the form of a hierarchical tree; the leaves on these
  trees are scalars.

  Also see `Absinthe.Type.Object`.

  ## Built-In Scalars

  The following built-in scalar types are defined:

  * `:boolean` - Represents `true` or `false`. See the [GraphQL Specification](https://facebook.github.io/graphql/#sec-Boolean).
  * `:float` - Represents signed double‐precision fractional values as specified by [IEEE 754](http://en.wikipedia.org/wiki/IEEE_floating_point). See the [GraphQL Specification](https://facebook.github.io/graphql/#sec-Float).
  * `:id` - Represents a unique identifier, often used to refetch an object or as key for a cache. The ID type is serialized in the same way as a String; however, it is not intended to be human‐readable. See the [GraphQL Specification](https://facebook.github.io/graphql/#sec-ID).
  * `:integer` - Represents a signed 32‐bit numeric non‐fractional value, greater than or equal to -2^31 and less than 2^31. Note that Absinthe uses the full word `:integer` to identify this type, but its `name` (used by variables, for instance), is `"Int"`. See the [GraphQL Specification](https://facebook.github.io/graphql/#sec-Int).
  * `:string` - Represents textual data, represented as UTF‐8 character sequences. The String type is most often used by GraphQL to represent free‐form human‐readable text. See the [GraphQL Specification](https://facebook.github.io/graphql/#sec-String).
  ## Examples

  Supporting a time format in ISOz format, using [Timex](http://hexdocs.pm/timex):

  ```
  use Absinthe.Field.Definitions
  # Also loaded by `use Absinthe.Field.Schema`

  @absinthe :type
  def time do
    %Absinthe.Type.Scalar{
      description: "Time (in ISOz format)",
      parse: &Timex.DateFormat.parse(&1, "{ISOz}"),
      serialize: &Timex.DateFormat.format!(&1, "{ISOz}")
    }
  end
  ```
  """

  use Absinthe.Introspection.Kind
  use Absinthe.Type.Definitions

  alias __MODULE__
  alias Absinthe.Flag
  alias Absinthe.Type

  @typedoc """
  A defined scalar type.

  Note new scalars should be defined using `@absinthe :type` from `Absinthe.Type.Definitions`.

  * `:name` - The name of scalar. Should be a TitleCased `binary`. Set automatically when using `@absinthe :type` from `Absinthe.Type.Definitions`.
  * `:description` - A nice description for introspection.
  * `:serialize` - A function used to convert a value to a form suitable for JSON serialization
  * `:parse` - A function used to convert the raw, incoming form of a scalar to the canonical internal format.

  The `:reference` key is for internal use.
"""
  @type t :: %{name: binary, description: binary, serialize: (value_t -> any), parse: (any -> {:ok, value_t} | :error), reference: Type.Reference.t}

  @typedoc "The internal, canonical representation of a scalar value"
  @type value_t :: any

  defstruct name: nil, description: nil, serialize: nil, parse: nil, reference: nil

  @absinthe :type
  @doc false
  @spec integer :: t
  def integer do
    %Scalar{name: "Int",
            description: """
            The `Int` scalar type represents non-fractional signed whole numeric
            values. Int can represent values between -(2^53 - 1) and 2^53 - 1 since
            represented in JSON as double-precision floating point numbers specified
            by [IEEE 754](http://en.wikipedia.org/wiki/IEEE_floating_point).
            """ |> String.replace("\n", " "),
            serialize: &(&1),
            parse: parse_with([Absinthe.Language.IntValue], &parse_int/1)}
  end

  @absinthe :type
  @doc false
  @spec float :: t
  def float do
    %Scalar{name: "Float",
            description: """
            The `Float` scalar type represents signed double-precision fractional
            values as specified by
            [IEEE 754](http://en.wikipedia.org/wiki/IEEE_floating_point).
            """ |> String.replace("\n", " "),
            serialize: &(&1),
            parse: parse_with([Absinthe.Language.IntValue,
                               Absinthe.Language.FloatValue], &parse_float/1)}
  end

  @absinthe :type
  @doc false
  @spec string :: t
  def string do
    %Scalar{name: "String",
            description: """
            The `String` scalar type represents textual data, represented as UTF-8
            character sequences. The String type is most often used by GraphQL to
            represent free-form human-readable text.
            """ |> String.replace("\n", " "),
            serialize: &to_string/1,
            parse: parse_with([Absinthe.Language.StringValue], &parse_string/1)}
  end

  @absinthe :type
  @graphql_spec "https://facebook.github.io/graphql/#sec-ID"
  @spec id :: t
  def id do
    %Scalar{name: "ID",
            description: """
            The `ID` scalar type represents a unique identifier, often used to
            refetch an object or as key for a cache. The ID type appears in a JSON
            response as a String; however, it is not intended to be human-readable.
            When expected as an input type, any string (such as `"4"`) or integer
            (such as `4`) input value will be accepted as an ID.
            """ |> String.replace("\n", " "),
            serialize: &to_string/1,
            parse: parse_with([Absinthe.Language.IntValue,
                               Absinthe.Language.StringValue], &parse_string/1)}
  end

  @absinthe :type
  @graphql_spec "https://facebook.github.io/graphql/#sec-Boolean"
  @spec boolean :: t
  def boolean do
    %Scalar{name: "Boolean",
            description: """
            The `Boolean` scalar type represents `true` or `false`.
            """ |> String.replace("\n", " "),
            serialize: &(&1),
            parse: parse_with([Absinthe.Language.BooleanValue],
                              &parse_boolean/1)}
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
  @spec parse_with([atom], (any -> value_t)) :: (any -> {:ok, value_t} | :error)
  defp parse_with(node_types, coercion) do
    fn
      %{value: value} = node ->
        if Enum.is_member?(node_types, node) do
          coercion.(value)
        else
          nil
        end
      other ->
        coercion.(other)
    end
  end

end
