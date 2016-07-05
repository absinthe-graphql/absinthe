defmodule Absinthe.Blueprint do

  alias __MODULE__

  defstruct [
    operations: [],
    types: [],
    directives: [],
  ]

  @type t :: %__MODULE__{
    operations: [Blueprint.Operation.t],
    types: [Blueprint.Schema.t],
    directives: [Blueprint.Schema.Directive.t],
  }

  @type node_t ::
      Blueprint.t
    | Blueprint.Directive.t
    | Blueprint.Field.t
    | Blueprint.Schema.t
    | Blueprint.Input.t
    | Blueprint.TypeReference.t
    | Blueprint.Operation.t
    | Blueprint.VariableDefinition.t

  defdelegate prewalk(blueprint, fun), to: Absinthe.Blueprint.Mapper
  defdelegate prewalk(blueprint, acc, fun), to: Absinthe.Blueprint.Mapper
  defdelegate postwalk(blueprint, fun), to: Absinthe.Blueprint.Mapper
  defdelegate postwalk(blueprint, acc, fun), to: Absinthe.Blueprint.Mapper
end
