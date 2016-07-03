defmodule Absinthe.Blueprint do

  alias __MODULE__

  defstruct [
    operations: [],
    types: [],
    directives: [],
  ]

  @type t :: %__MODULE__{
    operations: [Blueprint.Operation.t],
    types: [Blueprint.IDL.type_t],
    directives: [Blueprint.IDL.Directive.t],
  }

  @type node_t ::
      Blueprint.Directive
    | Blueprint.Field
    | Blueprint.IDL.ArgumentDefinition
    | Blueprint.IDL.DirectiveDefinition
    | Blueprint.IDL.EnumTypeDefinition
    | Blueprint.IDL.FieldDefinition
    | Blueprint.IDL.InputObjectTypeDefinition
    | Blueprint.IDL.InputValueDefinition
    | Blueprint.IDL.InterfaceTypeDefinition
    | Blueprint.IDL.ObjectTypeDefinition
    | Blueprint.IDL.ScalarTypeDefinition
    | Blueprint.IDL.UnionTypeDefinition
    | Blueprint.Input.Argument
    | Blueprint.Input.Boolean
    | Blueprint.Input.Enum
    | Blueprint.Input.Field
    | Blueprint.Input.Float
    | Blueprint.Input.Integer
    | Blueprint.Input.List
    | Blueprint.Input.Object
    | Blueprint.Input.String
    | Blueprint.Input.Variable
    | Blueprint.ListType
    | Blueprint.NamedType
    | Blueprint.NonNullType
    | Blueprint.Operation
    | Blueprint.VariableDefinition

  @type type_reference_t ::
      Blueprint.ListType.t
    | Blueprint.NonNullType.t
    | Blueprint.NamedType.t

end
