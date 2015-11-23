defmodule ExGraphQL do

  defmodule ExecutionError do
    defexception message: "execution failed"
  end

  defmodule SyntaxError do
    defexception line: nil, errors: "Syntax error"

    def message(exception) do
      "#{exception.errors} on line #{exception.line}"
    end
  end

  @spec tokenize(binary) :: {:ok, [tuple]} | {:error, binary}
  def tokenize(input) do
    case :ex_graphql_lexer.string(input |> to_char_list) do
      {:ok, tokens, _line_count} -> {:ok, tokens}
      other -> other
    end
  end

  @spec parse(binary) :: {:ok, ExGraphQL.Language.Document.t} | {:error, tuple}
  @spec parse(ExGraphQL.Language.Source.t) :: {:ok, ExGraphQL.Language.Document.t} | {:error, tuple}
  def parse(input) when is_binary(input) do
    parse(%ExGraphQL.Language.Source{body: input})
  end
  def parse(input) do
    case input.body |> tokenize do
      {:ok, []} -> {:ok, %ExGraphQL.Language.Document{}}
      {:ok, tokens} -> :ex_graphql_parser.parse(tokens)
      other -> other
    end
  end

  @spec parse!(binary) :: ExGraphQL.Language.Document.t
  @spec parse!(ExGraphQL.Language.Source.t) :: ExGraphQL.Language.Document.t
  def parse!(input) when is_binary(input) do
    parse!(%ExGraphQL.Language.Source{body: input})
  end
  def parse!(input) do
    case parse(input) do
      {:ok, result} -> result
      {:error, {line_number, _, errs}} -> raise SyntaxError, source: input, line_number: line_number, error: errs
    end
  end

  @spec run(ExGraphQL.Type.Schema.t, binary | ExGraphQL.Language.Source.t | ExGraphQL.Language.Document.t, Keyword.t) :: {:ok, map} | {:error, any}
  def run(schema, %ExGraphQL.Language.Document{} = document, options) do
    case execute(schema, document, options) do
      {:ok, execution} -> {:ok, execution.result}
      other -> other
    end
  end
  def run(schema, input, options) do
    case parse(input) do
      {:ok, document} -> run(schema, document, options)
      other -> other
    end
  end

  @spec run(ExGraphQL.Type.Schema.t, binary | ExGraphQL.Language.Source.t | ExGraphQL.Language.Document.t) :: {:ok, map} | {:error, any}
  def run(schema, input), do: run(schema, input, [])

  @spec run!(ExGraphQL.Type.Schema.t, binary | ExGraphQL.Language.Source.t | ExGraphQL.Language.Document.t, Keyword.t) :: map
  def run!(schema, input, options) do
    case run(schema, input, options) do
      {:ok, result} -> result
      {:error, err} -> raise ExecutionError, message: err
    end
  end

  @spec run!(ExGraphQL.Type.Schema.t, binary | ExGraphQL.Language.Source.t | ExGraphQL.Language.Document.t) :: map
  def run!(schema, input), do: run!(schema, input, [])

  #
  # EXECUTION
  #

  defp execute(schema, document, options) do
    %ExGraphQL.Execution{schema: schema, document: document}
    |> ExGraphQL.Execution.run(options)
  end

end
