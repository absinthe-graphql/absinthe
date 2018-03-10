defmodule Absinthe.Blueprint.Document.Operation do
  @moduledoc false

  alias Absinthe.Blueprint

  @enforce_keys [:name, :type]
  defstruct [
    :name,
    :type,
    current: false,
    selections: [],
    directives: [],
    variable_definitions: [],
    variable_uses: [],
    fragment_uses: [],
    source_location: nil,
    # Populated by phases
    flags: %{},
    schema_node: nil,
    complexity: nil,
    provided_values: %{},
    errors: []
  ]

  @type t :: %__MODULE__{
          name: nil | String.t(),
          type: :query | :mutation | :subscription,
          current: boolean,
          directives: [Blueprint.Directive.t()],
          selections: [Blueprint.Document.selection_t()],
          variable_definitions: [Blueprint.Document.VariableDefinition.t()],
          variable_uses: [Blueprint.Input.Variable.Use.t()],
          fragment_uses: [Blueprint.Document.Fragment.Named.Use.t()],
          source_location: nil | Blueprint.Document.SourceLocation.t(),
          schema_node: nil | Absinthe.Type.Object.t(),
          complexity: nil | non_neg_integer,
          provided_values: %{String.t() => nil | Blueprint.Input.t()},
          flags: Blueprint.flags_t(),
          errors: [Absinthe.Phase.Error.t()]
        }

  @doc """
  Determine if a fragment or variable is used by an operation.
  """
  @spec uses?(t, Blueprint.node_t()) :: boolean
  def uses?(op, %Blueprint.Document.Fragment.Named{} = node) do
    do_uses?(op.fragment_uses, node)
  end

  def uses?(op, %Blueprint.Input.Variable{} = node) do
    do_uses?(op.variable_uses, node)
  end

  # Whether a node is marked as used in a use list
  @spec do_uses?([Blueprint.use_t()], Blueprint.node_t()) :: boolean
  defp do_uses?(list, node) do
    Enum.find(list, &(&1.name == node.name))
  end
end
