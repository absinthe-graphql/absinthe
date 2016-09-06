defmodule Absinthe.Blueprint.Document.Operation do

  alias Absinthe.Blueprint

  @enforce_keys [:name, :type]
  defstruct [
    :name,
    :type,
    selections: [],
    directives: [],
    variable_definitions: [],
    source_location: nil,
    # Populated by phases
    flags: [],
    schema_node: nil,
    provided_values: %{},
    fields: [],
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: nil | String.t,
    type: :query | :mutation | :subscription,
    directives: [Blueprint.Directive.t],
    selections: [Blueprint.Document.selection_t],
    variable_definitions: [Blueprint.Document.VariableDefinition.t],
    source_location: nil | Blueprint.Document.SourceLocation.t,
    schema_node: nil | Absinthe.Type.Object.t,
    provided_values: %{String.t => nil | Blueprint.Input.t},
    flags: [atom],
    fields: [Blueprint.Document.Field.t],
    errors: [Absinthe.Phase.Error.t],
  }

  @spec variables_used(Blueprint.Document.Operation.t, Blueprint.t) :: [Blueprint.Input.Variable.Reference.t]
  def variables_used(%__MODULE__{} = node, doc) do
    {_, {_, vars}} = Blueprint.prewalk(node, {doc.fragments, []}, &do_variables_used/2)
    vars
  end

  @target_fragments [
    Blueprint.Document.Fragment.Inline,
    Blueprint.Document.Fragment.Named,
  ]

  def do_variables_used(%Blueprint.Document.Fragment.Spread{} = node, {fragments, vars} = acc) do
    target_fragment = Enum.find(fragments, &(&1.name == node.name))
    if target_fragment do
      {_, acc} = Blueprint.prewalk(target_fragment, acc, &do_variables_used/2)
      {node, acc}
    else
      {node, acc}
    end
  end
  def do_variables_used(%Blueprint.Input.Variable{} = node, {fragments, vars}) do
    ref = Blueprint.Input.Variable.to_reference(node)
    {node, {fragments, [ref | vars]}}
  end
  def do_variables_used(node, acc) do
    {node, acc}
  end

end
