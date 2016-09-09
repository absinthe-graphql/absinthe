defmodule Absinthe do

  @moduledoc """
  Documentation for the Absinthe package, a toolkit for building GraphQL
  APIs with Elixir.

  Absinthe aims to handle authoring GraphQL API schemas -- then supporting
  their introspection, validation, and execution according to the
[GraphQL specification](https://facebook.github.io/graphql/).

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

  For a grounding in GraphQL, I recommend you read through the following articles:

  * The [GraphQL Introduction](https://facebook.github.io/react/blog/2015/05/01/graphql-introduction.html) and [GraphQL: A data query language](https://code.facebook.com/posts/1691455094417024/graphql-a-data-query-language/) posts from Facebook.
  * The [Your First GraphQL Server](https://medium.com/@clayallsopp/your-first-graphql-server-3c766ab4f0a2#.m78ybemas) Medium post by Clay Allsopp. (Note this uses the [JavaScript GraphQL reference implementation](https://github.com/graphql/graphql-js).)
  * Other blog posts that pop up. GraphQL is young!
  * For the ambitious, the draft [GraphQL Specification](https://facebook.github.io/graphql/).

  You may also be interested in how GraphQL is used by [Relay](https://facebook.github.io/relay/), a "JavaScript frameword for building data-driven React applications."

  ## GraphQL using Absinthe

  The first thing you need to do is define a schema, we do this
  by using `Absinthe.Schema`.

  For details on the macros available to build a schema, see `Absinthe.Schema.Notation`

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
      field :name, :string, description: "The item's name"
      field :value, :integer, description: "Recently appraised value"
    end
  end
  ```

  Now we'll execute a query document against it with
  `run/2` or `run/3` (which return tuples), or their exception-raising
  equivalents, `run!/2` and `run!/3.

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

  defmodule SyntaxError do
    @moduledoc """
    An error during parsing.
    """
    defexception source: nil, location: nil, message: ""
    def message(exception) do
      "#{exception.message} on line #{exception.location.line}"
    end
  end

  def parse(input) do
    Absinthe.Phase.Parse.run(input)
  end

  @doc """
  Evaluates a query document against a schema, with options.

  ## Options

  * `:adapter` - The name of the adapter to use. See the `Absinthe.Adapter`
    behaviour and the `Absinthe.Adapter.Passthrough` and
    `Absinthe.Adapter.LanguageConventions` modules that implement it.
    (`Absinthe.Adapter.Passthrough` is the default value for this option.)
  * `:operation_name` - If more than one operation is present in the provided
    query document, this must be provided to select which operation to execute.
  * `:variables` - A map of provided variable values to be used when filling in
    arguments in the provided query document.
  * `:context` -> A map of the execution context.

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
    operation_name: binary,
  ]

  @spec run(binary | Absinthe.Language.Source.t | Absinthe.Language.Document.t, Absinthe.Schema.t, run_opts) :: {:ok, Absinthe.Execution.result_t} | {:error, any}
  def run(document, schema, options \\ []) do
    pipeline = Absinthe.Pipeline.for_document(schema, Map.new(options))
    Absinthe.Pipeline.run(document, pipeline)
  end

  @doc """
  Evaluates a query document against a schema, without options.

  ## Options

  See `run/3` for the available options.
  """
  @spec run!(binary | Absinthe.Language.Source.t | Absinthe.Language.Document.t, Absinthe.Schema.t, Keyword.t) :: Absinthe.Execution.result_t
  def run!(input, schema, options \\ []) do
    case run(input, schema, options) do
      {:ok, result} -> result
      {:error, err} -> raise ExecutionError, message: err
    end
  end

end
