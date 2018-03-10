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
    errors: []
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          arguments: [Blueprint.Input.Argument.t()],
          source_location: nil | Blueprint.Document.SourceLocation.t(),
          schema_node: nil | Absinthe.Type.Directive.t(),
          flags: Blueprint.flags_t(),
          errors: [Phase.Error.t()]
        }

  @spec expand(t, Blueprint.node_t()) :: {t, map}
  def expand(%__MODULE__{schema_node: %{expand: nil}}, node) do
    node
  end

  def expand(%__MODULE__{schema_node: %{expand: fun}} = directive, node) do
    args = Blueprint.Input.Argument.value_map(directive.arguments)
    fun.(args, node)
  end

  def expand(%__MODULE__{schema_node: nil}, node) do
    node
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
  def placement(%Blueprint.Document.Operation{}), do: :operation_definition
  def placement(%Blueprint.Schema.SchemaDefinition{}), do: :schema
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
