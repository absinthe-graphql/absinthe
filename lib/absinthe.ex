defmodule Absinthe do

  @moduledoc """
  Documentation for the Absinthe package, a toolkit for building GraphQL
  APIs with Elixir.

  Absinthe aims to handle authoring GraphQL API schemas -- then supporting
  their introspection, validation, and execution according to the
[GraphQL specification](https://facebook.github.io/graphql/).

  ## Building HTTP APIs

  **IMPORTANT**: For HTTP, you'll probably want to use
  [AbsinthePlug](https://hex.pm/projects/absinthe_plug) instead of executing
  GraphQL query documents yourself. Absinthe doesn't know or care about HTTP,
  so keep that in mind while reading through the documentation. While you'll
  be building schemas just as in the examples here, the actual calls to
  `Absinthe.run/3` and its friends are best left to
  [AbsinthePlug](https://hex.pm/projects/absinthe_plug) if you're providing an
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

    def query do
      %Absinthe.Type.Object{
        fields: fields(
          item: [
            type: :item,
            description: "Get an item by ID",
            args: args(
              id: [type: :id, description: "The ID of the item"]
            ),
            resolve: fn %{id: id}, _ ->
              {:ok, Map.get(@fake_db, id)}
            end
          ]
        )
      }
    end

    @absinthe :type
    def item do
      %Absinthe.Type.Object{
        description: "A valuable item",
        fields: fields(
          id: [type: :id],
          name: [type: :string, description: "The item's name"],
          value: [type: :integer, description: "Recently appraised value"]
        )
      }
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
  |> Absinthe.run(App.Schema, variables: %{id: params[:item_id]})
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
    defexception location: nil, msg: ""
    def message(exception) do
      "#{exception.msg} on line #{exception.location.line}"
    end
  end

  @doc false
  @spec tokenize(binary) :: {:ok, [tuple]} | {:error, binary}
  def tokenize(input) do
    case :absinthe_lexer.string(input |> to_char_list) do
      {:ok, tokens, _line_count} -> {:ok, tokens}
      other ->
        other
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
      {:ok, tokens} ->
        case :absinthe_parser.parse(tokens) do
          {:ok, _} = result ->
            result
          {:error, raw_error} ->
            {:error, format_parser_error(raw_error)}
        end
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
      {:error, err} -> raise SyntaxError, source: input, msg: err.message, location: err.locations[0]
    end
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
      {:error, err} ->
        {:ok, %{errors: [err]}}
      other ->
        other
    end
  end

  # TODO: Support modification by adapter
  # Convert a raw parser error into an `Execution.error_t`
  @doc false
  @spec format_parser_error({integer, :absinthe_parser, [char_list]}) :: Execution.error_t
  defp format_parser_error({line, :absinthe_parser, msgs}) do
    message = msgs |> Enum.map(&to_string/1) |> Enum.join("")
    %{message: message, locations: [%{line: line, column: 0}]}
  end

  @doc """
  Evaluates a query document against a schema, without options.

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

  @doc """
  Evaluates a query document against a schema, with options, raising an
  `Absinthe.SyntaxErorr` or `Absinthe.ExecutionError` if a problem occurs.
  """
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

  # TODO: Do separate validation phase here
  @doc """
  Validate a document.

  Note this is currently a stub that merely returns `:ok`,
  as validation and execution are currently conflated.

  Track https://github.com/CargoSense/absinthe/issues/17 for
  progress.
  """
  @spec validate(Language.Document.t, atom | Schema.t) :: :ok
  def validate(_doc, _schema) do
    :ok
  end

end
