defmodule Absinthe.Blueprint.Directive do
  @moduledoc false

  alias Absinthe.{Blueprint, Phase}

  @enforce_keys [:name]
  defstruct [
    :name,
    arguments: [],
    # When part of a Document
    source_location: nil,
    # Added by phases
    schema_node: nil,
    flags: %{},
    errors: [],
    __reference__: nil,
    __private__: []
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          arguments: [Blueprint.Input.Argument.t()],
          source_location: nil | Blueprint.SourceLocation.t(),
          schema_node: nil | Absinthe.Type.Directive.t(),
          flags: Blueprint.flags_t(),
          errors: [Phase.Error.t()],
          __reference__: nil,
          __private__: []
        }

  @spec expand(t, Blueprint.node_t()) :: {t, map}
  def expand(%__MODULE__{schema_node: nil}, node) do
    node
  end

  def expand(%__MODULE__{schema_node: type} = directive, node) do
    args = Blueprint.Input.Argument.value_map(directive.arguments)

    case Absinthe.Type.function(type, :expand) do
      nil ->
        # Directive is a no-op
        node

      expansion when is_function(expansion) ->
        expansion.(args, node)
    end
  end

  @doc """
  Determine the placement name for a given Blueprint node
  """
  @spec placement(Blueprint.node_t()) :: nil | atom
  def placement(%Blueprint.Document.Operation{type: type}), do: type
  def placement(%Blueprint.Document.Field{}), do: :field
  def placement(%Blueprint.Document.Fragment.Named{}), do: :fragment_definition
  def placement(%Blueprint.Document.Fragment.Spread{}), do: :fragment_spread
  def placement(%Blueprint.Document.Fragment.Inline{}), do: :inline_fragment
  def placement(%Blueprint.Schema.SchemaDefinition{}), do: :schema
  def placement(%Blueprint.Schema.SchemaDeclaration{}), do: :schema
  def placement(%Blueprint.Schema.ScalarTypeDefinition{}), do: :scalar
  def placement(%Blueprint.Schema.ObjectTypeDefinition{}), do: :object
  def placement(%Blueprint.Schema.FieldDefinition{}), do: :field_definition
  def placement(%Blueprint.Schema.InterfaceTypeDefinition{}), do: :interface
  def placement(%Blueprint.Schema.UnionTypeDefinition{}), do: :union
  def placement(%Blueprint.Schema.EnumTypeDefinition{}), do: :enum
  def placement(%Blueprint.Schema.EnumValueDefinition{}), do: :enum_value
  def placement(%Blueprint.Schema.InputObjectTypeDefinition{}), do: :input_object
  def placement(%Blueprint.Schema.InputValueDefinition{placement: placement}), do: placement
end
