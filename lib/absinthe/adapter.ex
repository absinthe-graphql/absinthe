defmodule Absinthe.Adapter do

  alias Absinthe.Execution

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour unquote(__MODULE__)

      alias Absinthe.Execution
      alias Absinthe.Language

      def load_document(%{definitions: definitions} = node) do
        %{node | definitions: definitions |> Enum.map(&load_ast_node/1)}
      end

      # Rename a AST node and traverse children
      defp load_ast_node(%Language.OperationDefinition{name: name, selection_set: selection_set} = node) do
        %{node | name: name |> to_internal_name(:operation), selection_set: load_ast_node(selection_set)}
      end
      defp load_ast_node(%Language.SelectionSet{selections: selections} = node) do
        %{node | selections: selections |> Enum.map(&load_ast_node/1)}
      end
      defp load_ast_node(%Language.Field{arguments: args, name: name, selection_set: selection_set} = node) do
        %{node | name: name |> to_internal_name(:field), selection_set: load_ast_node(selection_set), arguments: args |> Enum.map(&load_ast_node/1)}
      end
      defp load_ast_node(%Language.Argument{name: name} = node) do
        %{node | name: name |> to_internal_name(:argument)}
      end
      defp load_ast_node(nil) do
        nil
      end

      def dump_results(%{data: data, errors: _} = results) do
        %{results | data: do_dump_results(data)}
      end

      # Rename a result data value and traverse children
      defp do_dump_results(node) when is_map(node) do
        for {key, val} <- node, into: %{} do
          case key do
            name when is_binary(name) ->
              {to_external_name(name, :result), do_dump_results(val)}
            other ->
              {key, do_dump_results(val)}
          end
        end
      end
      defp do_dump_results([node|rest]) do
        [do_dump_results(node)|do_dump_results(rest)]
      end
      defp do_dump_results(node) do
        node
      end

      def to_internal_name(external_name, _role), do: external_name

      def to_external_name(internal_name, _role), do: internal_name

      def format_error(%{name: name, role: role, value: value}, locations) when is_function(value) do
        external_name = name |> to_external_name(role)
        %{
          message: value.(external_name) |> to_string,
          locations: locations
         }
      end
      def format_error(%{value: value, role: role} = error_info, locations) when is_binary(value) do
        role_name = role |> to_string |> String.capitalize
        %{error_info | value: &"#{role_name} `#{&1}': #{value}"}
        |> format_error(locations)
      end
      def format_error(%{value: value} = error_info, locations) do
        %{error_info | value: inspect(value)}
        |> format_error(locations)
      end

      defoverridable [load_document: 1,
                      dump_results: 1,
                      format_error: 2,
                      to_internal_name: 2,
                      to_external_name: 2]

    end
  end

  @doc """
  Convert the incoming (external) parsed document to the canonical (internal)
  representation that matches the schema.
  """
  @callback load_document(Absinthe.Language.Document.t) :: Absinthe.Language.Document.t

  @doc """
  Convert the canonical (internal) results to the output (external)
  representation.
  """
  @callback dump_results(Absinthe.Execution.result_t) :: any

  @typedoc "The lexical role of a name within the document/schema."
  @type role_t :: :operation | :field | :argument | :result

  @doc "Convert a name from an external name to an internal name."
  @callback to_internal_name(binary, role_t) :: binary

  @doc "Convert a name from an internal name to an external name."
  @callback to_external_name(binary, role_t) :: binary

  @doc """
  Format an error using `value` for `name` located at the provided line/column
  locations.

  ## Examples

      iex> format_error(%{name: "foo", role: :field, value: &"missing value '\#{&1}'"}, [%{line: 2, column: 4}])
      %{message: "missing value 'foo'", locations: [%{line: 2, column: 4}]}

      iex> format_error(%{name: "foo", role: :field, value: "missing value"}, [%{line: 2, column: 4}])
      %{message: "Field 'foo': missing value", locations: [%{line: 2, column: 4}]}

  """
  @callback format_error(Execution.error_info_t, [Execution.error_location_t]) :: Execution.error_t

end
