defmodule ExGraphQL.Adapter do

  alias ExGraphQL.Execution

  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)

      # TODO: Process keys through `to_internal_name`
      def load_variables(external_variables), do: external_variables

      # TODO: Process keys through `to_internal_name`
      def load_document(external_document), do: external_document

      # TODO: Process :data keys through `to_external_name`,
      #       support use of adapter in `Execution.format_error`
      def dump_results(internal_results), do: internal_results

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
        %{error_info | value: &"#{role_name} #{&1}: #{value}"}
        |> format_error(locations)
      end
      def format_error(%{value: value} = error_info, locations) do
        %{error_info | value: inspect(value)}
        |> format_error(locations)
      end

      defoverridable [load_variables: 1,
                      load_document: 1,
                      dump_results: 1,
                      format_error: 2,
                      to_internal_name: 2,
                      to_external_name: 2]
    end
  end

  @typedoc "An arbitrarily deep map of variables with binary key names"
  @type variable_map_t :: %{binary => variable_value_t}

  @typedoc "A value within a variable map"
  @type variable_value_t :: binary | integer | float | [variable_value_t] | variable_map_t

  @doc """
  Convert the incoming (external) variables to the internal representation
  that matches the schema.
  """
  @callback load_variables(map) :: variable_map_t

  @doc """
  Convert the incoming (external) parsed document to the canonical (internal)
  representation that matches the schema.
  """
  @callback load_document(ExGraphQL.Language.Document.t) :: ExGraphQL.Language.Document.t

  @doc """
  Convert the canonical (internal) results to the output (external)
  representation.
  """
  @callback dump_results(ExGraphQL.Execution.result_t) :: any

  @typedoc "The lexical role of a name within the document/schema"
  @type role_t :: :operation | :field | :variable | :argument

  @doc """
  Convert a name from an external name to an internal name
  """
  @callback to_internal_name(binary, role_t) :: binary

  @doc """
  Convert a name from an internal name to an external name
  """
  @callback to_external_name(binary, role_t) :: binary

  @doc """
  Format an error using `value` for `name` located at the provided line/column
  locations.

  ## Examples

    iex> format_error(%{name: "foo", value: &"missing value '\#{&1}'" end}, [%{line: 2, column: 4}])
    %{message: "missing value 'foo'", locations: [%{line: 2, column: 4}]}

    iex> format_error(%{name: "foo", value: "missing value"}, [%{line: 2, column: 4}])
    %{message: "Field 'foo': missing value", locations: [%{line: 2, column: 4}]}

  """
  @callback format_error(Execution.error_info_t, [Execution.error_location_t]) :: Execution.error_t

end
