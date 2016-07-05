defmodule Absinthe.Blueprint do

  alias __MODULE__

  defstruct [
    operations: [],
    types: [],
    directives: [],
  ]

  @type t :: %__MODULE__{
    operations: [Blueprint.Operation.t],
    types: [Blueprint.Schema.type_t],
    directives: [Blueprint.Schema.Directive.t],
  }

  @type node_t ::
      Blueprint.t
    | Blueprint.Directive.t
    | Blueprint.Field.t
    | Blueprint.Schema.ArgumentDefinition.t
    | Blueprint.Schema.DirectiveDefinition.t
    | Blueprint.Schema.EnumTypeDefinition.t
    | Blueprint.Schema.FieldDefinition.t
    | Blueprint.Schema.InputObjectTypeDefinition.t
    | Blueprint.Schema.InputValueDefinition.t
    | Blueprint.Schema.InterfaceTypeDefinition.t
    | Blueprint.Schema.ObjectTypeDefinition.t
    | Blueprint.Schema.ScalarTypeDefinition.t
    | Blueprint.Schema.UnionTypeDefinition.t
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
