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

  @spec parse(binary) :: {:ok, %ExGraphQL.AST.Document{}} | {:error, tuple}
  def parse(input) do
    case input |> tokenize do
      {:ok, tokens} -> :ex_graphql_parser.parse(tokens)
      other -> other
    end
  end

  @spec parse!(binary) :: %ExGraphQL.AST.Document{}
  def parse!(input) do
    case parse(input) do
      {:ok, result} -> result
      {:error, {line_number, _, errs}} -> raise SyntaxError, line_number: line_number, error: errs
    end
  end

  @spec execute(%ExGraphQL.Types.Schema{}, binary | %ExGraphQL.AST.Document{}) :: {:ok, %{}} | {:error, binary}
  def execute(schema, input) when is_binary(input) do
    case parse(input) do
      {:ok, document} -> execute(schema, document)
      other -> other
    end
  end
  def execute(schema, input) do
    {:ok, {:nope, :not_really}}
  end

  @spec execute!(%ExGraphQL.Types.Schema{}, binary | %ExGraphQL.AST.Document{}) :: %{}
  def execute!(schema, input) do
    case execute(schema, input) do
      {:ok, result} -> result
      {:error, err} -> raise ExecutionError, message: err
    end
  end

end
