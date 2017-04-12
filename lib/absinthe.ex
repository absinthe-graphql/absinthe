defmodule Absinthe do

  @moduledoc """
  Documentation for the Absinthe package, a toolkit for building GraphQL
  APIs with Elixir.

  Absinthe aims to handle authoring GraphQL API schemas -- then supporting
  their introspection, validation, and execution according to the
[GraphQL specification](https://facebook.github.io/graphql/).

  This documentation covers specific details of the Absinthe API. For
  guides, tutorials, GraphQL, and community information, see the
  [Absinthe Website](http://absinthe-graphql.org).

  ## Building HTTP APIs

  **IMPORTANT**: For HTTP, you'll probably want to use
  [AbsinthePlug](https://hex.pm/packages/absinthe_plug) instead of executing
  GraphQL query documents yourself. Absinthe doesn't know or care about HTTP,
  so keep that in mind while reading through the documentation. While you'll
  be building schemas just as in the examples here, the actual calls to
  `Absinthe.run/3` and its friends are best left to
  [AbsinthePlug](https://hex.pm/packages/absinthe_plug) if you're providing an
  HTTP API.

  ## Ecosystem

  Here are some additional projects you're likely to use in conjunction with
  Absinthe to launch an API:

  * [Ecto](http://hexdocs.pm/ecto) - a language integrated query and
  database wrapper.
  * [Phoenix](http://hexdocs.pm/phoenix) - the Phoenix web framework.
  * [Plug](http://hexdocs.pm/plug) - a specification and conveniences
  for composable modules in between web applications.
  * [Poison](http://hexdocs.pm/poison) - JSON serialization.

  ## GraphQL Basics

  For background on GraphQL, please visit the [GraphQL](http://graphql.org/)
  website.

  ## GraphQL using Absinthe

  The first thing you need to do is define a schema, we do this
  by using `Absinthe.Schema`.

  For details on the macros available to build a schema, see
  `Absinthe.Schema.Notation`

  Here we'll build a basic schema that defines one query field; a
  way to retrieve the data for an `item`, given an `id`. Users of
  the API can then decide what fields of the `item` they'd like
  returned.

  ```
  defmodule App.Schema do
    use Absinthe.Schema

    @fake_db %{
      "foo" => %{id: "foo", name: "Foo", value: 4},
      "bar" => %{id: "bar", name: "Bar", value: 5}
    }

    query do
      @desc "Get an item by ID"
      field :item, type: :item do

        @desc "The ID of the item"
        arg :id, :id

        resolve fn %{id: id}, _ ->
          {:ok, Map.get(@fake_db, id)}
        end
      end
    end

    @desc "A valuable item"
    object :item do

      field :id, :id

      @desc "The item's name"
      field :name, :string

      @desc "Recently appraised value"
      field :value, :integer

    end
  end
  ```

  Now we'll execute a query document against it with
  `run/2` or `run/3` (which return tuples), or their exception-raising
  equivalents, `run!/2` and `run!/3`.

  Let's get the `name` of an `item` with `id` `"foo"`:

  ```
  \"""
  {
    item(id: "foo") {
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
  |> Absinthe.run(App.Schema, variables: %{"id" => params[:item_id]})
  ```

  The result, if `params[:item_id]` was `"foo"`, would be the same:

  ```
  {:ok, %{data: %{"name" => "Foo"}}}
  ```

  `run!/2` and `run!/3` operate similarly, except they will raise
  `Absinthe.SytaxError` and `Absinthe.ExecutionError` if they cannot
  parse/execute the document.
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
    String.t =>
        nil
      | integer
      | float
      | boolean
      | binary
      | atom
      | result_selection_t
  }

  @type result_error_t ::
      %{message: String.t}
    | %{message: String.t,
        locations: [%{line: integer, column: integer}]}

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
    adapter: Absinthe.Adapter.t,
    root_value: term,
    operation_name: String.t,
    analyze_complexity: boolean,
    max_complexity: non_neg_integer | :infinity
  ]

  @spec run(binary | Absinthe.Language.Source.t | Absinthe.Language.Document.t, Absinthe.Schema.t, run_opts) :: {:ok, result_t} | {:error, String.t}
  def run(document, schema, options \\ []) do
    pipeline = Absinthe.Pipeline.for_document(schema, options)
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
  @spec run!(binary | Absinthe.Language.Source.t | Absinthe.Language.Document.t, Absinthe.Schema.t, Keyword.t) :: result_t | no_return
  def run!(input, schema, options \\ []) do
    case run(input, schema, options) do
      {:ok, result} -> result
      {:error, err} -> raise ExecutionError, message: err
    end
  end

end
