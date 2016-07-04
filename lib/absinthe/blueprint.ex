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
      Blueprint.t
    | Blueprint.Directive.t
    | Blueprint.Field.t
    | Blueprint.IDL.ArgumentDefinition.t
    | Blueprint.IDL.DirectiveDefinition.t
    | Blueprint.IDL.EnumTypeDefinition.t
    | Blueprint.IDL.FieldDefinition.t
    | Blueprint.IDL.InputObjectTypeDefinition.t
    | Blueprint.IDL.InputValueDefinition.t
    | Blueprint.IDL.InterfaceTypeDefinition.t
    | Blueprint.IDL.ObjectTypeDefinition.t
    | Blueprint.IDL.ScalarTypeDefinition.t
    | Blueprint.IDL.UnionTypeDefinition.t
    | Blueprint.Input.Argument.t
    | Blueprint.Input.Boolean.t
    | Blueprint.Input.Enum.t
    | Blueprint.Input.Field.t
    | Blueprint.Input.Float.t
    | Blueprint.Input.Integer.t
    | Blueprint.Input.List.t
    | Blueprint.Input.Object.t
    | Blueprint.Input.String.t
    | Blueprint.Input.Variable.t
    | Blueprint.ListType.t
    | Blueprint.NamedType.t
    | Blueprint.NonNullType.t
    | Blueprint.Operation.t
    | Blueprint.VariableDefinition.t

  @type type_reference_t ::
      Blueprint.ListType.t
    | Blueprint.NonNullType.t
    | Blueprint.NamedType.t

  defdelegate prewalk(blueprint, fun), to: Absinthe.Blueprint.Mapper
  defdelegate prewalk(blueprint, acc, fun), to: Absinthe.Blueprint.Mapper
  defdelegate postwalk(blueprint, fun), to: Absinthe.Blueprint.Mapper
  defdelegate postwalk(blueprint, acc, fun), to: Absinthe.Blueprint.Mapper
end
