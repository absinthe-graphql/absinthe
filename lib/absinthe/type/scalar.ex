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
  scalar :time do
    description "Time (in ISOz format)"
    parse &Timex.DateFormat.parse(&1, "{ISOz}")
    serialize &Timex.DateFormat.format!(&1, "{ISOz}")
  end
  ```
  """

  use Absinthe.Introspection.Kind

  alias Absinthe.Type

  def build(%{attrs: attrs}) do
    quote do: %unquote(__MODULE__){unquote_splicing(attrs)}
  end

  def serialize(%{serialize: serializer}, value) do
    serializer.(value)
  end

  def parse(%{parse: parser}, value, context \\ %{}) do
    case parser do
      parser when is_function(parser, 1) ->
        parser.(value)

      parser when is_function(parser, 2) ->
        parser.(value, context)
    end
  end

  @typedoc """
  A defined scalar type.

  Note new scalars should be defined using `Absinthe.Schema.Notation.scalar`.

  * `:name` - The name of scalar. Should be a TitleCased `binary`. Set Automatically by `Absinthe.Schema.Notation.scalar`.
  * `:description` - A nice description for introspection.
  * `:serialize` - A function used to convert a value to a form suitable for JSON serialization
  * `:parse` - A function used to convert the raw, incoming form of a scalar to the canonical internal format.

  The `:__private__` and `:__reference__` keys are for internal use.
  """
  @type t :: %__MODULE__{
          name: binary,
          description: binary,
          serialize: (value_t -> any),
          parse: (any -> {:ok, value_t} | :error),
          identifier: atom,
          __private__: Keyword.t(),
          __reference__: Type.Reference.t()
        }

  defstruct name: nil,
            description: nil,
            serialize: nil,
            parse: nil,
            identifier: nil,
            __private__: [],
            __reference__: nil

  @typedoc "The internal, canonical representation of a scalar value"
  @type value_t :: any

  if System.get_env("DEBUG_INSPECT") do
    defimpl Inspect do
      def inspect(scalar, _) do
        "#<Scalar:#{scalar.name}>"
      end
    end
  end
end
