defmodule Absinthe do

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
    case :absinthe_lexer.string(input |> to_char_list) do
      {:ok, tokens, _line_count} -> {:ok, tokens}
      other -> other
    end
  end

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

  @spec run(binary | Absinthe.Language.Source.t | Absinthe.Language.Document.t, atom | Absinthe.Schema.t, Keyword.t) :: {:ok, map} | {:error, any}
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

  @spec run(binary | Absinthe.Language.Source.t | Absinthe.Language.Document.t, atom | Absinthe.Schema.t) :: {:ok, map} | {:error, any}
  def run(input, schema), do: run(input, schema, [])

  @spec run!(binary | Absinthe.Language.Source.t | Absinthe.Language.Document.t, atom | Absinthe.Schema.t, Keyword.t) :: map
  def run!(input, schema, options) do
    case run(input, schema, options) do
      {:ok, result} -> result
      {:error, err} -> raise ExecutionError, message: err
    end
  end

  @spec run!(binary | Absinthe.Language.Source.t | Absinthe.Language.Document.t, atom | Absinthe.Schema.t) :: map
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
