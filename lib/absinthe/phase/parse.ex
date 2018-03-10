defmodule Absinthe.Phase.Parse do
  @moduledoc false

  use Absinthe.Phase

  alias Absinthe.{Language, Phase}

  @spec run(Language.Source.t(), Keyword.t()) :: Phase.result_t()
  def run(input, options \\ [])

  def run(%Absinthe.Blueprint{} = blueprint, options) do
    options = Map.new(options)

    case parse(blueprint.input) do
      {:ok, value} ->
        {:ok, %{blueprint | input: value}}

      {:error, error} ->
        blueprint
        |> add_validation_error(error)
        |> handle_error(options)
    end
  end

  def run(input, options) do
    run(%Absinthe.Blueprint{input: input}, options)
  end

  defp add_validation_error(bp, error) do
    put_in(bp.execution.validation_errors, [error])
  end

  def handle_error(blueprint, %{jump_phases: true, result_phase: abort_phase}) do
    {:jump, blueprint, abort_phase}
  end

  def handle_error(blueprint, _) do
    {:error, blueprint}
  end

  @spec tokenize(binary) :: {:ok, [tuple]} | {:error, binary}
  defp tokenize(input) do
    chars = :erlang.binary_to_list(input)

    case :absinthe_lexer.string(chars) do
      {:ok, tokens, _line_count} ->
        {:ok, tokens}

      {:error, raw_error, _} ->
        {:error, format_raw_parse_error(raw_error)}
    end
  end

  @spec parse(binary) :: {:ok, Language.Document.t()} | {:error, tuple}
  @spec parse(Language.Source.t()) :: {:ok, Language.Document.t()} | {:error, tuple}
  defp parse(input) when is_binary(input) do
    parse(%Language.Source{body: input})
  end

  defp parse(input) do
    try do
      case input.body |> tokenize do
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

  @spec format_raw_parse_error({integer, :absinthe_parser, [charlist]}) :: Phase.Error.t()
  defp format_raw_parse_error({line, :absinthe_parser, msgs}) do
    message = msgs |> Enum.map(&to_string/1) |> Enum.join("")
    %Phase.Error{message: message, locations: [%{line: line, column: 0}], phase: __MODULE__}
  end

  @spec format_raw_parse_error({integer, :absinthe_lexer, {atom, charlist}}) :: Phase.Error.t()
  defp format_raw_parse_error({line, :absinthe_lexer, {problem, field}}) do
    message = "#{problem}: #{field}"
    %Phase.Error{message: message, locations: [%{line: line, column: 0}], phase: __MODULE__}
  end

  @unknown_error_msg "An unknown error occurred during parsing"
  @spec format_raw_parse_error(map) :: Phase.Error.t()
  defp format_raw_parse_error(%{} = error) do
    detail =
      if Exception.exception?(error) do
        ": " <> Exception.message(error)
      else
        ""
      end

    %Phase.Error{message: @unknown_error_msg <> detail, phase: __MODULE__}
  end
end
