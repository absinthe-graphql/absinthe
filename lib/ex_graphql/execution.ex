defmodule ExGraphQL.Execution do

  alias ExGraphQL.Language
  alias ExGraphQL.Type

  alias __MODULE__

  @type error_t :: %{message: binary, locations: [%{line: integer, column: integer}]}

  @type t :: %{schema: Type.Schema.t, document: Language.Document.t, variables: map, validate: boolean, selected_operation: ExGraphQL.Type.ObjectType.t, operation_name: atom, errors: [error_t], categorized: boolean, strategy: atom}
  defstruct schema: nil, document: nil, variables: %{}, fragments: %{}, operations: %{}, validate: true, selected_operation: nil, operation_name: nil, errors: [], categorized: false, strategy: nil

  def run(execution, options \\ []) do
    raw = execution |> Map.merge(options |> Enum.into(%{}))
    case prepare(raw) do
      {:ok, prepared} -> execute(prepared)
      other -> other
    end
  end

  def prepare(execution) do
    defined = execution |> categorize_definitions
    case selected_operation(defined) do
      {:ok, operation} ->
        %{defined | selected_operation: operation}
        |> set_variables
        |> validate
      other -> other
    end
  end

  @spec format_error(binary | any, Language.t) :: error_t
  def format_error(message, %{loc: %{start_line: line}}) when is_binary(message) do
    %{message: message |> to_string, locations: [%{line: line, column: 0}]}
  end
  def format_error(non_binary_message, %{start_line: _} = ast_node) do
    non_binary_message
    |> inspect
    |> format_error(ast_node)
  end

  @spec resolve_type(t, t, t) :: t | nil
  def resolve_type(_target, nil = _child_type, _parent_type) do
    nil
  end
  def resolve_type(target, nil = _child_type, %{__struct__: Type.Union} = parent_type) do
    parent_type
    |> Type.Union.resolve_type(target)
  end
  def resolve_type(_target, %{__struct__: Type.Union} = child_type, parent_type) do
    child_type |> Type.Union.member?(parent_type) || nil
  end
  def resolve_type(target, %{__struct__: Type.InterfaceType} = child_type, _parent_type) do
    target
    |> Type.InterfaceType.resolve_type
  end
  def resolve_type(_target, child_type, parent_type) when child_type == parent_type do
    parent_type
  end
  def resolve_type(_target, _child_type, _parent_type) do
    nil
  end

  def stringify_keys(node) when is_map(node) do
    for {key, val} <- node, into: %{}, do: {key |> to_string, stringify_keys(val)}
  end
  def stringify_keys([node|rest]) do
    [stringify_keys(node)|stringify_keys(rest)]
  end
  def stringify_keys(node) do
    node
  end

  defp execute(execution) do
    execution
    |> Execution.Runner.run
  end

  @doc "Categorize definitions in the execution document as operations or fragments"
  @spec categorize_definitions(t) :: t
  def categorize_definitions(%{document: %Language.Document{definitions: definitions}} = execution) do
    categorize_definitions(%{execution | operations: %{}, fragments: %{}, categorized: true}, definitions)
  end

  defp categorize_definitions(execution, []) do
    execution
  end
  defp categorize_definitions(%{operations: operations} = execution, [%{__struct__: ExGraphQL.Language.OperationDefinition, name: name} = definition | rest]) do
    categorize_definitions(%{execution | operations: operations |> Map.put(name, definition)}, rest)
  end
  defp categorize_definitions(%{fragments: fragments} = execution, [%{__struct__: ExGraphQL.Language.FragmentDefinition, name: name} = definition | rest]) do
    categorize_definitions(%{execution | fragments: fragments |> Map.put(name, definition)}, rest)
  end

  @doc "Validate an execution"
  @spec validate(t) :: {:ok, t} | {:error, binary}
  def validate(%{validate: true}) do
    {:error, "Validation is not currently supported"}
  end
  def validate(execution) do
    {:ok, execution}
  end

  def selected_operation(%{categorized: false}) do
    {:error, "Call Execution.categorize_definitions first"}
  end
  def selected_operation(%{selected_operation: value}) when not is_nil(value) do
    {:ok, value}
  end
  def selected_operation(%{operations: ops, operation_name: nil}) when ops == %{} do
    {:ok, nil}
  end
  def selected_operation(%{operations: ops, operation_name: nil}) when map_size(ops) == 1 do
    op = ops |> Map.values |> List.first
    {:ok, op}
  end
  def selected_operation(%{operations: ops, operation_name: name}) do
    case Map.get(ops, name) do
      nil -> {:error, "No operation with name: #{name}"}
      op -> {:ok, op}
    end
  end
  def selected_operation(%{operations: ops, operation_name: nil}) do
    {:error, "Multiple operations available, but no operation_name provided"}
  end

  def set_variables(%{schema: schema, selected_operation: selected_op, variables: variables} = execution) do
    case Execution.Variables.build(schema, selected_op.variable_definitions, variables) do
      %{values: values, errors: new_errors} ->
        %{execution | variables: values, errors: new_errors ++ execution.errors}
    end
  end

end
