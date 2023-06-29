defmodule Absinthe.Phase.Parse do
  @moduledoc false

  use Absinthe.Phase

  alias Absinthe.{Blueprint, Language, Phase}

  # This is because Dialyzer is telling us tokenizing can never fail,
  # but we know it's possible.
  @dialyzer {:no_match, run: 2}
  @spec run(Language.Source.t() | %Blueprint{}, Keyword.t()) :: Phase.result_t()
  def run(input, options \\ [])

  def run(%Absinthe.Blueprint{} = blueprint, options) do
    case parse(blueprint.input, options) do
      {:ok, value} ->
        {:ok, %{blueprint | input: value}}

      {:error, error} ->
        blueprint
        |> add_validation_error(error)
        |> handle_error(Map.new(options))
    end
  end

  def run(input, options) do
    run(%Absinthe.Blueprint{input: input}, options)
  end

  # This is because Dialyzer is telling us tokenizing can never fail,
  # but we know it's possible.
  @dialyzer {:no_unused, add_validation_error: 2}
  defp add_validation_error(bp, error) do
    put_in(bp.execution.validation_errors, [error])
  end

  def handle_error(blueprint, %{jump_phases: true, result_phase: abort_phase}) do
    {:jump, blueprint, abort_phase}
  end

  def handle_error(blueprint, _) do
    {:error, blueprint}
  end

  @spec tokenize(binary, Keyword.t()) :: {:ok, [tuple]} | {:error, String.t()}
  def tokenize(input, options \\ []) do
    case Absinthe.Lexer.tokenize(input, options) do
      {:error, rest, loc} ->
        {:error, format_raw_parse_error({:lexer, rest, loc})}

      {:error, :exceeded_token_limit} ->
        {:error, %Phase.Error{message: "Token limit exceeded", phase: __MODULE__}}

      other ->
        other
    end
  end

  # This is because Dialyzer is telling us tokenizing can never fail,
  # but we know it's possible.
  @dialyzer {:no_match, parse: 2}
  @spec parse(binary | Language.Source.t(), Keyword.t()) ::
          {:ok, Language.Document.t()} | {:error, tuple}
  defp parse(input, options) when is_binary(input) do
    parse(%Language.Source{body: input}, options)
  end

  defp parse(input, options) do
    try do
      case tokenize(input.body, options) do
        {:ok, []} ->
          {:ok, %Language.Document{}}

        {:ok, tokens} ->
          case :absinthe_parser.parse(tokens) do
            {:ok, _doc} = result ->
              result

            {:error, raw_error} ->
              {:error, format_raw_parse_error(raw_error)}
          end

        other ->
          other
      end
    rescue
      error ->
        {:error, format_raw_parse_error(error)}
    end
  end

  @spec format_raw_parse_error({{integer, integer}, :absinthe_parser, [charlist]}) ::
          Phase.Error.t()
  defp format_raw_parse_error({{line, column}, :absinthe_parser, msgs}) do
    message = msgs |> Enum.map(&to_string/1) |> Enum.join("")
    %Phase.Error{message: message, locations: [%{line: line, column: column}], phase: __MODULE__}
  end

  @spec format_raw_parse_error({integer, :absinthe_parser, [charlist]}) ::
          Phase.Error.t()
  defp format_raw_parse_error({line, :absinthe_parser, msgs}) do
    message = msgs |> Enum.map(&to_string/1) |> Enum.join("")
    %Phase.Error{message: message, locations: [%{line: line, column: 0}], phase: __MODULE__}
  end

  @spec format_raw_parse_error({:lexer, String.t(), {line :: pos_integer, column :: pos_integer}}) ::
          Phase.Error.t()
  defp format_raw_parse_error({:lexer, rest, {line, column}}) do
    sample_slice = String.slice(rest, 0, 10)
    sample = if String.valid?(sample_slice), do: sample_slice, else: inspect(sample_slice)

    message = "Parsing failed at `#{sample}`"
    %Phase.Error{message: message, locations: [%{line: line, column: column}], phase: __MODULE__}
  end

  @unknown_error_msg "An unknown error occurred during parsing"
  @spec format_raw_parse_error(map) :: Phase.Error.t()
  defp format_raw_parse_error(%{} = error) do
    detail =
      if is_exception(error) do
        ": " <> Exception.message(error)
      else
        ""
      end

    %Phase.Error{message: @unknown_error_msg <> detail, phase: __MODULE__}
  end
end
