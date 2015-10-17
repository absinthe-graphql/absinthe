defmodule ExGraphQL do

  alias ExGraphQL.Validation

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

  @spec parse(binary) :: {:ok, %ExGraphQL.Language.Document{}} | {:error, tuple}
  @spec parse(%ExGraphQL.Source{}) :: {:ok, %ExGraphQL.Language.Document{}} | {:error, tuple}
  def parse(input) when is_binary(input) do
    parse(%ExGraphQL.Source{body: input})
  end
  def parse(input) do
    case input.body |> tokenize do
      {:ok, tokens} -> :ex_graphql_parser.parse(tokens)
      other -> other
    end
  end

  @spec parse!(binary) :: %ExGraphQL.Language.Document{}
  @spec parse!(%ExGraphQL.Source{}) :: %ExGraphQL.Language.Document{}
  def parse!(input) when is_binary(input) do
    parse!(%ExGraphQL.Source{body: input})
  end
  def parse!(input) do
    case parse(input) do
      {:ok, result} -> result
      {:error, {line_number, _, errs}} -> raise SyntaxError, source: input, line_number: line_number, error: errs
    end
  end

  @spec run(%ExGraphQL.Types.Schema{}, binary | %ExGraphQL.Source{} | %ExGraphQL.Language.Document{}) :: {:ok, %{}} | {:error, any}
  def run(schema, %ExGraphQL.Language.Document{} = document) do
    {:ok, {:nope, document}}
  end
  def run(schema, input) do
    case parse(input) do
      {:ok, document} -> run(schema, document)
      other -> other
    end
  end

  @spec run!(%ExGraphQL.Types.Schema{}, binary | %ExGraphQL.Source{} | %ExGraphQL.Language.Document{}) :: %{}
  def run!(schema, input) do
    case run(schema, input) do
      {:ok, result} -> result
      {:error, err} -> raise ExecutionError, message: err
    end
  end

  @spec validate(%ExGraphQL.Types.Schema{}, %ExGraphQL.Language.Document{}) :: :ok | {:error, [any]}
  def validate(schema, document) do
    Validation.validate(schema, document)
  end

end
