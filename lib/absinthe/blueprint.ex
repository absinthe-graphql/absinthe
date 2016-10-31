defmodule Absinthe.Blueprint do

  @moduledoc """
  Represents the graphql document to be executed.

  Please see the code itself for more information on individual blueprint sub
  modules.
  """

  alias __MODULE__

  defstruct [
    operations: [],
    types: [],
    directives: [],
    fragments: [],
    schema: nil,
    adapter: nil,
    # Added by phases
    flags: %{},
    errors: [],
    resolution: %Blueprint.Document.Resolution{}
  ]

  @type t :: %__MODULE__{
    operations: [Blueprint.Document.Operation.t],
    types: [Blueprint.Schema.t],
    directives: [Blueprint.Schema.DirectiveDefinition.t],
    fragments: [Blueprint.Document.Fragment.Named.t],
    schema: nil | Absinthe.Schema.t,
    adapter: nil | Absinthe.Adapter.t,
    # Added by phases
    errors: [Blueprint.Phase.Error.t],
    flags: Blueprint.flags_t,
    resolution: Blueprint.Document.Resolution.t
  }

  @type node_t ::
      Blueprint.t
    | Blueprint.Directive.t
    | Blueprint.Document.t
    | Blueprint.Schema.t
    | Blueprint.Input.t
    | Blueprint.TypeReference.t

  @type use_t ::
      Blueprint.Document.Fragment.Named.Use.t
    | Blueprint.Input.Variable.Use.t

  @type flags_t :: %{atom => module}

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

  @spec fragment(t, String.t) :: nil | Blueprint.Document.Fragment.Named.t
  def fragment(blueprint, name) do
    Enum.find(blueprint.fragments, &(&1.name == name))
  end

  @doc """
  Add a flag to a node.
  """
  @spec put_flag(node_t, atom, module) :: node_t
  def put_flag(node, flag, mod) do
    update_in(node.flags, &Map.put(&1, flag, mod))
  end

  @doc """
  Determine whether a flag has been set on a node.
  """
  @spec flagged?(node_t, atom) :: boolean
  def flagged?(node, flag) do
    Map.has_key?(node.flags, flag)
  end

  @doc """
  Get the currently selected operation.
  """
  @spec current_operation(t) :: nil | Blueprint.Operation.t
  def current_operation(blueprint) do
    Enum.find(blueprint.operations, &(&1.current == true))
  end

  @doc """
  Update the current operation.
  """
  @spec update_current(t, (Blueprint.Operation.t -> Blueprint.Operation.t)) :: t
  def update_current(blueprint, change) do
    ops = Enum.map(blueprint.operations, fn
      %{current: true} = op ->
        change.(op)
      other ->
        other
    end)
    %{blueprint | operations: ops}
  end

end
