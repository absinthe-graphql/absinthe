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
    directives: [Blueprint.Schema.Directive.t],
  }

  @type node_t ::
      Blueprint.t
    | Blueprint.Document.t
    | Blueprint.Schema.t
    | Blueprint.Input.t
    | Blueprint.TypeReference.t

  defdelegate prewalk(blueprint, fun), to: Absinthe.Blueprint.Mapper
  defdelegate prewalk(blueprint, acc, fun), to: Absinthe.Blueprint.Mapper
  defdelegate postwalk(blueprint, fun), to: Absinthe.Blueprint.Mapper
  defdelegate postwalk(blueprint, acc, fun), to: Absinthe.Blueprint.Mapper
end
