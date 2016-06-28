defmodule Absinthe.IR.Field do
  defstruct [
    name: nil,
    fields: [],
    arguments: [],
    directives: [],
    errors: [],
    ast_node: nil,
    schema_type: nil,
    type_condition: nil
  ]

  @type t :: %__MODULE__{
    name: String.t,
    fields: [__MODULE__.t],
    arguments: [Absinthe.IR.Argument.t],
    directives: [Absinthe.IR.Directive.t],
    errors: [Absinthe.IR.Error.t],
    ast_node: Absinthe.Language.t,
    schema_type: Absinthe.Type.t,
    type_condition: Absinthe.IR.TypeCondition.t
  }
end
