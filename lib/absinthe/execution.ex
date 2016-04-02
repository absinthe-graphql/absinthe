defmodule Absinthe.Execution do

  @moduledoc false

  alias Absinthe.Language
  alias Absinthe.Type
  alias Absinthe.Flag

  alias __MODULE__

  @typedoc "The raw information for an error"
  @type error_info_t :: %{name: binary, role: Absinthe.Adapter.role_t, value: ((binary) -> binary) | any}

  @typedoc "A document location for an error"
  @type error_location_t :: %{line: integer, column: integer}

  @typedoc "The canonical representation of an error, as returned in the result"
  @type error_t :: %{message: binary, locations: [error_location_t]}

  @typedoc "The canonical result representation of an execution"
  @type result_t :: %{data: %{binary => any}, errors: [error_t]} | %{data: %{binary => any}} | %{errors: [error_t]}

  @type t :: %{schema: Schema.t, document: Language.Document.t, variables: map, selected_operation: Absinthe.Type.Object.t, operation_name: binary, errors: [error_t], categorized: boolean, strategy: atom, adapter: atom, resolution: Execution.Resolution.t, context: map, root_value: any}
  defstruct schema: nil, document: nil, variables: %{}, fragments: %{}, operations: %{}, selected_operation: nil, operation_name: nil, errors: [], categorized: false, strategy: nil, adapter: nil, resolution: nil, context: %{}, root_value: nil

  @doc false
  def run(execution, raw_opts \\ []) do
    options = raw_opts |> Enum.into(%{})
    execution
    |> prepare(options)
    |> case do
      {:ok, prepared} -> execute(prepared)
      other -> other
    end
  end

  @doc false
  @spec prepare(t) :: t
  def prepare(raw_execution, options \\ %{}) do
    execution = raw_execution
    |> Map.put(:context, Map.get(options, :context, %{}))
    |> Map.put(:adapter, Map.get(options, :adapter))
    |> Map.put(:root_value, Map.get(options, :root_value))
    |> Map.put(:operation_name, Map.get(options, :operation_name))
    |> add_variables(Map.get(options, :variables, %{}))
    |> add_configured_adapter
    |> adapt
    |> categorize_definitions

    with {:ok, operation} <- selected_operation(execution) do
      {:ok, %{execution | selected_operation: operation}}
    end
  end

  defp add_variables(execution, raw_vars) do
    %{execution | variables: %__MODULE__.Variables{raw: raw_vars}}
  end

  @default_adapter Absinthe.Adapter.LanguageConventions

  # Add the configured adapter to an execution
  @doc false
  @spec add_configured_adapter(t) :: t
  def add_configured_adapter(%{adapter: nil} = execution) do
    %{execution | adapter: configured_adapter}
  end
  def add_configured_adapter(execution) do
    execution
  end

  @spec configured_adapter :: atom
  defp configured_adapter do
    Application.get_env(:absinthe, :adapter, @default_adapter)
  end

  defp adapt(%{document: document, variables: variables, adapter: adapter} = execution) do
    %{execution |
      document: adapter.load_document(document),
      variables: Map.update!(variables, :raw, &adapter.load_variables(&1)),
    }
  end

  @default_column_number 0

  # Add an error to an execution.
  #
  #     iex> execution |> put_error(:field, "myField", "is not good!", at: ast_node)
  #
  @doc false
  @spec put_error(t, Adapter.role_t, binary | atom, binary | function, Keyword.t) :: t
  def put_error(execution, role, name, message, options) do
    %{at: ast_node} = options |> Enum.into(%{})
    error = format_error(
      execution,
      %{
        name: name |> to_string,
        role: role,
        value: message
      },
      ast_node
    )
    %{execution | errors: [error | execution.errors]}
  end

  @doc false
  @spec format_error(t, error_info_t, Language.t) :: error_t
  def format_error(%{adapter: adapter}, error_info, %{loc: %{start_line: line}}) do
    adapter.format_error(error_info, [%{line: line, column: @default_column_number}])
  end
  def format_error(%{adapter: adapter}, error_info, _) do
    adapter.format_error(error_info)
  end


  # Format an error, without using the adapter (useful when reporting on types and other unadapted names)
  @doc false
  @spec format_error(binary, Language.t) :: error_t
  def format_error(message, %{loc: %{start_line: line}}) do
    %{message: message, locations: [%{line: line, column: @default_column_number}]}
  end

  # Stringify keys in an arbitrarily deep structure with maps
  @doc false
  @spec stringify_keys(any) :: any
  def stringify_keys(node) when is_map(node) do
    for {key, val} <- node, into: %{}, do: {key |> to_string, stringify_keys(val)}
  end
  def stringify_keys([node|rest]) do
    [stringify_keys(node)|stringify_keys(rest)]
  end
  def stringify_keys(node) do
    node
  end

  defp execute(%{adapter: adapter} = execution) do
    case Execution.Runner.run(execution) do
      {:ok, results} ->
        {:ok, adapter.dump_results(results)}
      other ->
        other
    end
  end

  # Categorize definitions in the execution document as operations or fragments
  @doc false
  @spec categorize_definitions(t) :: t
  def categorize_definitions(%{document: %Language.Document{definitions: definitions}} = execution) do
    categorize_definitions(%{execution | operations: %{}, fragments: %{}, categorized: true}, definitions)
  end

  defp categorize_definitions(execution, []) do
    execution
  end
  defp categorize_definitions(%{operations: operations} = execution, [%Absinthe.Language.OperationDefinition{name: name} = definition | rest]) do
    categorize_definitions(%{execution | operations: operations |> Map.put(name, definition)}, rest)
  end
  defp categorize_definitions(%{fragments: fragments} = execution, [%Absinthe.Language.Fragment{name: name} = definition | rest]) do
    categorize_definitions(%{execution | fragments: fragments |> Map.put(name, definition)}, rest)
  end

  @doc false
  @spec selected_operation(t) :: {:ok, Absinthe.Type.Object.t | nil} | {:error, binary}
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
    ops
    |> Map.values
    |> List.first
    |> Flag.as(:ok)
  end
  def selected_operation(%{operations: ops, operation_name: name}) when not is_nil(name) do
    case Map.get(ops, name) do
      nil -> {:error, "No operation with name: #{name}"}
      op -> {:ok, op}
    end
  end
  def selected_operation(%{operations: _, operation_name: nil}) do
    {:error, "Multiple operations available, but no operation_name provided"}
  end

  # Get the concrete type (if necessary) of a possibly abstract type
  @spec concrete_type(Type.t, any, Execution.t) :: Type.t
  def concrete_type(%{__struct__: mod} = type, target, execution) when mod in [Type.Interface, Type.Union] do
    mod.resolve_type(type, target, execution)
  end
  def concrete_type(type, _, _) do
    type
  end

end
