defmodule Absinthe.Blueprint do

  alias __MODULE__

  defstruct [
    operations: [],
    types: [],
    directives: [],
    fragments: [],
    errors: [],
    schema: nil,
  ]

  @type t :: %__MODULE__{
    operations: [Blueprint.Document.Operation.t],
    types: [Blueprint.Schema.t],
    directives: [Blueprint.Schema.DirectiveDefinition.t],
    fragments: [Blueprint.Document.Fragment.Named.t],
    errors: [Blueprint.Phase.Error.t],
    schema: nil | Absinthe.Schema.t,
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

  def find(blueprint, fun) do
    {_, found} = Blueprint.prewalk(blueprint, nil, fn
      node, nil ->
        if fun.(node) do
          {node, node}
        else
          {node, nil}
        end
      node, found ->
        # Already found
        {node, found}
    end)
    found
  end


end
