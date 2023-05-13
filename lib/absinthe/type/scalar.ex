defmodule Absinthe.Type.Scalar do
  @moduledoc """
  Represents a primitive value.

  GraphQL responses take the form of a hierarchical tree; the leaves on these
  trees are scalars.

  Also see `Absinthe.Type.Object`.

  ## Built-In Scalars

  The following built-in scalar types are defined:

  * `:boolean` - Represents `true` or `false`. See the [GraphQL Specification](https://www.graphql.org/learn/schema/#scalar-types).
  * `:float` - Represents signed double-precision fractional values as specified by [IEEE 754](https://en.wikipedia.org/wiki/IEEE_754). See the [GraphQL Specification](https://www.graphql.org/learn/schema/#scalar-types).
  * `:id` - Represents a unique identifier, often used to refetch an object or as key for a cache. The ID type is serialized in the same way as a String; however, it is not intended to be human-readable. See the [GraphQL Specification](https://www.graphql.org/learn/schema/#scalar-types).
  * `:integer` - Represents non-fractional signed whole numeric value. **By default it is not compliant with the GraphQl Specification**, it can represent values between `-(2^53 - 1)` and `2^53 - 1` as specified by [IEEE 754](https://en.wikipedia.org/wiki/IEEE_754). To use the [GraphQl compliant Int](https://spec.graphql.org/October2021/#sec-Int), representing values between `-2^31` and `2^31 - 1`, in your schema `use Absinthe.Schema, use_spec_compliant_int_scalar: true`.
  * `:string` - Represents textual data, represented as UTF-8 character sequences. The String type is most often used by GraphQL to represent free-form human-readable text. See the [GraphQL Specification](https://www.graphql.org/learn/schema/#scalar-types).


  ## Built-in custom types

  Note that absinthe includes a few generic extra scalar types in `Absinthe.Type.Custom`,
  these are not part of the GraphQL spec thus they must be explicitly imported.
  Consider using them before implementing a custom type.


  ## Example

  Supporting ISO8601 week date format, using [Timex](https://hexdocs.pm/timex):

  ```
  scalar :iso_week_date do
    description "ISO8601 week date (ex: 2022-W42-2)"
    parse &Timex.parse(&1, "{YYYY}-W{Wiso}-{WDmon}")
    serialize &Timex.format!(&1, "{YYYY}-W{Wiso}-{WDmon}")
  end
  ```
  """

  use Absinthe.Introspection.TypeKind, :scalar

  alias Absinthe.Type

  @doc false
  defdelegate functions(), to: Absinthe.Blueprint.Schema.ScalarTypeDefinition

  def serialize(type, value) do
    Type.function(type, :serialize).(value)
  end

  def parse(type, value, context \\ %{}) do
    case Type.function(type, :parse) do
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
          identifier: atom,
          __private__: Keyword.t(),
          definition: module,
          __reference__: Type.Reference.t()
        }

  defstruct name: nil,
            description: nil,
            identifier: nil,
            __private__: [],
            definition: nil,
            __reference__: nil,
            parse: nil,
            serialize: nil,
            open_ended: false

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
