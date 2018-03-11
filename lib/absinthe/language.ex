defmodule Absinthe.Language do
  @moduledoc false

  alias Absinthe.Language

  alias __MODULE__

  @type t ::
          Language.Argument.t()
          | Language.BooleanValue.t()
          | Language.Directive.t()
          | Language.Document.t()
          | Language.EnumTypeDefinition.t()
          | Language.EnumValue.t()
          | Language.Field.t()
          | Language.FieldDefinition.t()
          | Language.FloatValue.t()
          | Language.Fragment.t()
          | Language.FragmentSpread.t()
          | Language.InlineFragment.t()
          | Language.InputObjectTypeDefinition.t()
          | Language.InputValueDefinition.t()
          | Language.IntValue.t()
          | Language.InterfaceTypeDefinition.t()
          | Language.ListType.t()
          | Language.ListValue.t()
          | Language.NamedType.t()
          | Language.NonNullType.t()
          | Language.ObjectField.t()
          | Language.ObjectTypeDefinition.t()
          | Language.ObjectValue.t()
          | Language.OperationDefinition.t()
          | Language.ScalarTypeDefinition.t()
          | Language.SelectionSet.t()
          | Language.Source.t()
          | Language.StringValue.t()
          | Language.TypeExtensionDefinition.t()
          | Language.UnionTypeDefinition.t()
          | Language.Variable.t()
          | Language.VariableDefinition.t()

  # Value nodes
  @type value_t ::
          Language.Variable.t()
          | Language.IntValue.t()
          | Language.FloatValue.t()
          | Language.StringValue.t()
          | Language.BooleanValue.t()
          | Language.EnumValue.t()
          | Language.ListValue.t()
          | Language.ObjectValue.t()

  # Type reference nodes
  @type type_reference_t ::
          Language.NamedType.t() | Language.ListType.t() | Language.NonNullType.t()

  # Type definition nodes
  @type type_definition_t ::
          Language.ObjectTypeDefinition.t()
          | Language.InterfaceTypeDefinition.t()
          | Language.UnionTypeDefinition.t()
          | Language.ScalarTypeDefinition.t()
          | Language.EnumTypeDefinition.t()
          | Language.InputObjectTypeDefinition.t()
          | Language.TypeExtensionDefinition.t()

  @type loc_t :: %{start_line: nil | integer, end_line: nil | integer}

  @type input_t ::
          Language.BooleanValue
          | Language.EnumValue
          | Language.FloatValue
          | Language.IntValue
          | Language.ListValue
          | Language.ObjectValue
          | Language.StringValue
          | Language.Variable

  # Unwrap an AST type from a NonNullType
  @doc false
  @spec unwrap(Language.NonNullType.t() | t) :: t
  def unwrap(%Language.NonNullType{type: t}), do: t
  def unwrap(type), do: type
end
