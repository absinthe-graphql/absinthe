defmodule Absinthe do
  @moduledoc """
  Documentation for the Absinthe package, a toolkit for building GraphQL
  APIs with Elixir.

  For usage information, see [the documentation](http://hexdocs.pm/absinthe), which
  includes guides, API information for important modules, and links to useful resources.
  """

  defmodule ExecutionError do
    @moduledoc """
    An error during execution.
    """
    defexception message: "execution failed"
  end

  defmodule AnalysisError do
    @moduledoc """
    An error during analysis.
    """
    defexception message: "analysis failed"
  end

  @type result_selection_t :: %{
          String.t() =>
            nil
            | integer
            | float
            | boolean
            | binary
            | atom
            | [result_selection_t]
        }

  @type result_error_t ::
          %{message: String.t()}
          | %{message: String.t(), locations: [%{line: integer, column: integer}]}

  @type result_t ::
          %{data: nil | result_selection_t}
          | %{data: nil | result_selection_t, errors: [result_error_t]}
          | %{errors: [result_error_t]}

  @doc """
  Evaluates a query document against a schema, with options.

  ## Options

  * `:adapter` - The name of the adapter to use. See the `Absinthe.Adapter`
    behaviour and the `Absinthe.Adapter.Passthrough` and
    `Absinthe.Adapter.LanguageConventions` modules that implement it.
    (`Absinthe.Adapter.LanguageConventions` is the default value for this option.)
  * `:operation_name` - If more than one operation is present in the provided
    query document, this must be provided to select which operation to execute.
  * `:variables` - A map of provided variable values to be used when filling in
    arguments in the provided query document.
  * `:context` -> A map of the execution context.
  * `:root_value` -> A root value to use as the source for toplevel fields.
  * `:analyze_complexity` -> Whether to analyze the complexity before
  executing an operation.
  * `:max_complexity` -> An integer (or `:infinity`) for the maximum allowed
  complexity for the operation being executed.

  ## Examples

  ```
  \"""
  query GetItemById($id: ID) {
    item(id: $id) {
      name
    }
  }
  \"""
  |> Absinthe.run(App.Schema, variables: %{"id" => params[:item_id]})
  ```

  See the `Absinthe` module documentation for more examples.

  """
  @type run_opts :: [
          context: %{},
          adapter: Absinthe.Adapter.t(),
          root_value: term,
          operation_name: String.t(),
          analyze_complexity: boolean,
          max_complexity: non_neg_integer | :infinity
        ]

  @type run_result :: {:ok, result_t} | {:error, String.t()}

  @spec run(
          binary | Absinthe.Language.Source.t() | Absinthe.Language.Document.t(),
          Absinthe.Schema.t(),
          run_opts
        ) :: run_result
  def run(document, schema, options \\ []) do
    pipeline =
      schema
      |> Absinthe.Pipeline.for_document(options)

    case Absinthe.Pipeline.run(document, pipeline) do
      {:ok, %{result: result}, _phases} ->
        {:ok, result}

      {:error, msg, _phases} ->
        {:error, msg}
    end
  end

  @doc """
  Evaluates a query document against a schema, without options.

  ## Options

  See `run/3` for the available options.
  """
  @spec run!(
          binary | Absinthe.Language.Source.t() | Absinthe.Language.Document.t(),
          Absinthe.Schema.t(),
          Keyword.t()
        ) :: result_t | no_return
  def run!(input, schema, options \\ []) do
    case run(input, schema, options) do
      {:ok, result} -> result
      {:error, err} -> raise ExecutionError, message: err
    end
  end
end
