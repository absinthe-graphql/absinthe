defmodule Absinthe do

  @moduledoc """
  Documentation for the Absinthe package, a toolkit for building GraphQL
  APIs with Elixir.

  Absinthe aims to handle authoring GraphQL API schemas -- then supporting
  their introspection, validation, and execution according to the
[GraphQL specification](https://facebook.github.io/graphql/).

  Here are some additional projects you're likely to use in conjunction with
  Absinthe to launch an API:

  * [Ecto](http://hexdocs.pm/ecto) - a language integrated query and
  database wrapper.
  * [Phoenix](http://hexdocs.pm/phoenix) - the Phoenix web framework.
  * [Plug](http://hexdocs.pm/plug) - a specification and conveniences
  for composable modules in between web applications.
    * An Absinthe-specific package for Plug is on our roadmap.
  * [Poison](http://hexdocs.pm/poison) - JSON serialization

  ## Basic Usage

  See the documentation for `Absinthe.Schema` and `run/3`.

  """

  defmodule ExecutionError do
    @moduledoc """
    An error during execution.
    """
    defexception message: "execution failed"
  end

  defmodule SyntaxError do
    @moduledoc """
    An error during parsing.
    """
    defexception line: nil, errors: "Syntax error"
    def message(exception) do
      "#{exception.errors} on line #{exception.line}"
    end
  end

  @doc false
  @spec tokenize(binary) :: {:ok, [tuple]} | {:error, binary}
  def tokenize(input) do
    case :absinthe_lexer.string(input |> to_char_list) do
      {:ok, tokens, _line_count} -> {:ok, tokens}
      other -> other
    end
  end

  @doc false
  @spec parse(binary) :: {:ok, Absinthe.Language.Document.t} | {:error, tuple}
  @spec parse(Absinthe.Language.Source.t) :: {:ok, Absinthe.Language.Document.t} | {:error, tuple}
  def parse(input) when is_binary(input) do
    parse(%Absinthe.Language.Source{body: input})
  end
  def parse(input) do
    case input.body |> tokenize do
      {:ok, []} -> {:ok, %Absinthe.Language.Document{}}
      {:ok, tokens} -> :absinthe_parser.parse(tokens)
      other -> other
    end
  end

  @doc false
  @spec parse!(binary) :: Absinthe.Language.Document.t
  @spec parse!(Absinthe.Language.Source.t) :: Absinthe.Language.Document.t
  def parse!(input) when is_binary(input) do
    parse!(%Absinthe.Language.Source{body: input})
  end
  def parse!(input) do
    case parse(input) do
      {:ok, result} -> result
      {:error, {line_number, _, errs}} -> raise SyntaxError, source: input, line_number: line_number, error: errs
    end
  end

  @doc """
  Evaluates a query document against a schema, with options.

  ## Options

  * `:adapter` - The name of the adapter to use. See the `Absinthe.Adapter` behaviour and the `Absinthe.Adapter.Passthrough` and `Absinthe.Adapter.LanguageConventions` modules that implement it. (`Absinthe.Adapter.Passthrough` is the default value for this option.)
  * `:operation_name` - If more than one operation is present in the provided query document, this must be provided to select which operation to execute.
  * `:variables` - A map of provided variable values to be used when filling in arguments in the provided query document.

  ## Examples

  ```
  \"""
  {
    item(id: "123") {
      name
    }
  }
  \"""
  |> Absinthe.run(App.Schema)
  ```

  Results are returned in a tuple, and are maps with `:data` and/or `:errors` keys, suitable for serialization
  back to the client.

  ```
  {:ok, %{data: %{"name" => "Foo"}}}
  ```

  You can also provide values for variables defined in the query document
  (supporting, eg, values passed as query string parameters):

  ```
  \"""
  query GetItemById($id: ID) {
    item(id: $id) {
      name
    }
  }
  \"""
  |> Absinthe.run(App.Schema, variables: %{id: params[:item_id]})
  ```

  """
  @spec run(binary | Absinthe.Language.Source.t | Absinthe.Language.Document.t, atom | Absinthe.Schema.t, Keyword.t) :: {:ok, Absinthe.Execution.result_t} | {:error, any}
  def run(%Absinthe.Language.Document{} = document, schema, options) do
    case execute(schema, document, options) do
      {:ok, result} ->
        {:ok, result}
      other ->
        other
    end
  end
  def run(input, schema, options) do
    case parse(input) do
      {:ok, document} ->
        run(document, schema, options)
      other ->
        other
    end
  end

  @doc "Evaluates a query document against a schema, without options."
  @spec run(binary | Absinthe.Language.Source.t | Absinthe.Language.Document.t, atom | Absinthe.Schema.t) :: {:ok, Absinthe.Execution.result_t} | {:error, any}
  def run(input, schema), do: run(input, schema, [])

  @doc """
  Evaluates a query document against a schema, with options, raising an `Absinthe.ExecutionError` if a problem occurs

  ## Options

  See `run/3` for the available options.
  """
  @spec run!(binary | Absinthe.Language.Source.t | Absinthe.Language.Document.t, atom | Absinthe.Schema.t, Keyword.t) :: Absinthe.Execution.result_t
  def run!(input, schema, options) do
    case run(input, schema, options) do
      {:ok, result} -> result
      {:error, err} -> raise ExecutionError, message: err
    end
  end

  @doc "Evaluates a query document against a schema, with options, raising an `Absinthe.ExecutionError` if a problem occurs."
  @spec run!(binary | Absinthe.Language.Source.t | Absinthe.Language.Document.t, atom | Absinthe.Schema.t) :: Absinthe.Execution.result_t
  def run!(input, schema), do: run!(input, schema, [])


  @spec find_schema(Absinthe.Schema.t | atom) :: Absinthe.Schema.t
  defp find_schema(schema_module) when is_atom(schema_module), do: schema_module.schema
  defp find_schema(schema), do: schema

  #
  # EXECUTION
  #

  @spec execute(Absinthe.Schema.t | atom, Absinthe.Language.Document.t, Keyword.t) :: Absinthe.Execution.result_t
  defp execute(schema_ref, document, options) do
    schema = find_schema(schema_ref)
    %Absinthe.Execution{schema: schema, document: document}
    |> Absinthe.Execution.run(options)
  end

end
