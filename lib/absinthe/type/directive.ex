defmodule Absinthe.Type.Directive do
  @moduledoc """
  Used by the GraphQL runtime as a way of modifying execution
  behavior.

  Type system creators will usually not create these directly.
  """

  alias Absinthe.Type
  alias Absinthe.Language
  use Absinthe.Introspection.Kind

  @typedoc """
  A defined directive.

  * `:name` - The name of the directivee. Should be a lowercase `binary`. Set automatically.
  * `:description` - A nice description for introspection.
  * `:args` - A map of `Absinthe.Type.Argument` structs. See `Absinthe.Schema.Notation.arg/2`.
  * `:locations` - A list of places the directives can be used.
  * `:repeatable` - A directive may be defined as repeatable by including the “repeatable” keyword

  The `:__reference__` key is for internal use.
  """
  @type t :: %{
          name: binary,
          description: binary,
          identifier: atom,
          args: map,
          locations: [location],
          expand: (map, Absinthe.Blueprint.node_t() -> atom),
          definition: module,
          repeatable: boolean,
          __private__: Keyword.t(),
          __reference__: Type.Reference.t()
        }

  @type location ::
          :query | :mutation | :field | :fragment_definition | :fragment_spread | :inline_fragment

  defstruct name: nil,
            description: nil,
            identifier: nil,
            args: nil,
            locations: [],
            expand: nil,
            definition: nil,
            repeatable: false,
            __private__: [],
            __reference__: nil

  @doc false
  defdelegate functions, to: Absinthe.Blueprint.Schema.DirectiveDefinition

  # Whether the directive is active in `place`
  @doc false
  @spec on?(t, Language.t()) :: boolean
  def on?(%{locations: locations}, place) do
    Enum.any?(locations, &do_on?(&1, place))
  end

  # Operations
  defp do_on?(location, %Language.OperationDefinition{operation: location}), do: true
  defp do_on?(:field, %Language.Field{}), do: true
  defp do_on?(:fragment_definition, %Language.Fragment{}), do: true
  defp do_on?(:fragment_spread, %Language.FragmentSpread{}), do: true
  defp do_on?(:inline_fragment, %Language.InlineFragment{}), do: true
  defp do_on?(:schema, %Language.SchemaDefinition{}), do: true
  defp do_on?(:schema, %Language.SchemaDeclaration{}), do: true
  defp do_on?(:scalar, %Language.ScalarTypeDefinition{}), do: true
  defp do_on?(:object, %Language.ObjectTypeDefinition{}), do: true
  defp do_on?(:field_definition, %Language.FieldDefinition{}), do: true
  defp do_on?(:interface, %Language.InterfaceTypeDefinition{}), do: true
  defp do_on?(:union, %Language.UnionTypeDefinition{}), do: true
  defp do_on?(:enum, %Language.EnumTypeDefinition{}), do: true
  defp do_on?(:enum_value, %Language.EnumValueDefinition{}), do: true
  defp do_on?(:input_object, %Language.InputObjectTypeDefinition{}), do: true
  defp do_on?(:argument_definition, %Language.InputValueDefinition{}), do: true
  defp do_on?(:input_field_definition, %Language.InputValueDefinition{}), do: true
  defp do_on?(_, _), do: false
end
