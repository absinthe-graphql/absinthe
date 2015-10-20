defmodule ExGraphQL.Language do

  @type t :: __MODULE__.Argument.t | __MODULE__.BooleanValue.t | __MODULE__.Directive.t | __MODULE__.Document.t | __MODULE__.EnumTypeDefinition.t | __MODULE__.EnumValue.t | __MODULE__.Field.t | __MODULE__.FieldDefinition.t | __MODULE__.FloatValue.t | __MODULE__.FragmentDefinition.t | __MODULE__.FragmentSpread.t | __MODULE__.InlineFragment.t | __MODULE__.InputObjectTypeDefinition.t | __MODULE__.InputValueDefinition.t | __MODULE__.IntValue.t | __MODULE__.InterfaceTypeDefinition.t | __MODULE__.ListType.t | __MODULE__.ListValue.t | __MODULE__.NamedType.t | __MODULE__.NonNullType.t | __MODULE__.ObjectField.t | __MODULE__.ObjectTypeDefinition.t | __MODULE__.ObjectValue.t | __MODULE__.OperationDefinition.t | __MODULE__.ScalarTypeDefinition.t | __MODULE__.SelectionSet.t | __MODULE__.Source.t | __MODULE__.StringValue.t | __MODULE__.TypeExtensionDefinition.t | __MODULE__.UnionTypeDefinition.t | __MODULE__.Variable.t | __MODULE__.VariableDefinition.t

  @doc "Value nodes"
  @type value_t :: __MODULE__.Variable.t | __MODULE__.IntValue.t | __MODULE__.FloatValue.t | __MODULE__.StringValue.t | __MODULE__.BooleanValue.t | __MODULE__.EnumValue.t | __MODULE__.ListValue.t | __MODULE__.ObjectValue.t

  @doc "Type reference nodes"
  @type type_reference_t :: __MODULE__.NamedType.t | __MODULE__.ListType.t | __MODULE__.NonNullType.t

  @doc "Type definition nodes"
  @type type_definition_t :: __MODULE__.ObjectTypeDefinition.t | __MODULE__.InterfaceTypeDefinition.t | __MODULE__.UnionTypeDefinition.t | __MODULE__.ScalarTypeDefinition.t | __MODULE__.EnumTypeDefinition.t | __MODULE__.InputObjectTypeDefinition.t | __MODULE__.TypeExtensionDefinition.t

  @type loc_t :: %{start: nil | integer,
                   end:   nil | integer}

end
