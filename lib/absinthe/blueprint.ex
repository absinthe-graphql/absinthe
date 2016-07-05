defmodule Absinthe.Blueprint do

  alias __MODULE__

  defstruct [
    operations: [],
    types: [],
    directives: [],
  ]

  @type t :: %__MODULE__{
    operations: [Blueprint.Document.Operation.t],
    types: [Blueprint.Schema.t],
    directives: [Blueprint.Schema.DirectiveDefinition.t],
  }

  @type node_t ::
      Blueprint.t
    | Blueprint.Directive.t
    | Blueprint.Document.t
    | Blueprint.Schema.t
    | Blueprint.Input.t
    | Blueprint.TypeReference.t

  defdelegate prewalk(blueprint, fun), to: Absinthe.Blueprint.Transform
  defdelegate prewalk(blueprint, acc, fun), to: Absinthe.Blueprint.Transform
  defdelegate postwalk(blueprint, fun), to: Absinthe.Blueprint.Transform
  defdelegate postwalk(blueprint, acc, fun), to: Absinthe.Blueprint.Transform
end
