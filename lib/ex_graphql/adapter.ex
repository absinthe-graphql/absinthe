defmodule ExGraphQL.Adapter do

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

      def to_internal_name(_role, external_name), do: external_name

      def to_external_name(_role, internal_name), do: internal_name

      defoverridable [load_variables: 1,
                      load_document: 1,
                      dump_results: 1,
                      to_internal_name: 2,
                      to_external_name: 2]
    end
  end

  @doc """
  Convert the incoming (external) variables to the internal representation
  that matches the schema.
  """
  @callback load_variables(%{binary => any}) :: %{binary => any}

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
  @callback to_internal_name(role_t, binary) :: binary

  @doc """
  Convert a name from an internal name to an external name
  """
  @callback to_external_name(role_t, binary) :: binary

end
