defmodule Absinthe.Pipeline do

  alias Absinthe.Phase
  alias __MODULE__

  require Logger

  @type input_t :: any
  @type output_t :: %{errors: [Phase.Error.t]}

  @type phase_config_t :: Phase.t | {Phase.t, [any]}

  @type t :: [phase_config_t | [phase_config_t]]

  @spec run(input_t, t) :: {:ok, output_t} | {:error, String.t}
  def run(input, pipeline) do
    case do_run(input, pipeline) do
      {:ok, _} = halted_with_user_errors ->
        halted_with_user_errors
      {:error, _} = halted_with_developer_errors ->
        halted_with_developer_errors
      completed ->
        {:ok, completed}
    end
  end

  @spec for_document(Absinthe.Schema.t) :: t
  @spec for_document(Absinthe.Schema.t, Keyword.t) :: t
  def for_document(schema, options \\ []) do
    options = Map.new(options)
    adapter = Map.get(options, :adapter, Absinthe.Adapter.LanguageConventions)
    variables = Map.new(Map.get(options, :variables, []))
    operation_name = Map.get(options, :operation_name)
    context = options[:context]
    root_value = options[:root_value]
    [
      Phase.Parse,
      Phase.Blueprint,
      {Phase.Document.CurrentOperation, [operation_name]},
      Phase.Document.Uses,
      Phase.Document.Validation.structural_pipeline,
      {Phase.Document.Variables, [variables]},
      Phase.Document.Arguments.Normalize,
      {Phase.Schema, [schema, adapter]},
      Phase.Validation.KnownTypeNames,
      Phase.Document.Arguments.Coercion,
      Phase.Document.Arguments.Data,
      Phase.Document.Arguments.Defaults,
      Phase.Document.Validation.data_pipeline,
      Phase.Document.Directives,
      Phase.Document.Flatten,
      {Phase.Document.Execution.Resolution, [context, root_value]},
      Phase.Document.Execution.Data
    ]
  end

  @spec for_schema(nil | Absinthe.Schema.t) :: t
  @spec for_schema(nil | Absinthe.Schema.t, Absinthe.Adapter.t) :: t
  def for_schema(prototype_schema, adapter \\ Absinthe.Adapter.LanguageConventions) do
    [
      Phase.Parse,
      Phase.Blueprint,
      {Phase.Schema, [prototype_schema, adapter]},
      Phase.Validation.KnownTypeNames,
      Phase.Schema.Validation.pipeline
    ]
  end

  @doc """
  Return the part of a pipeline before a specific phase.
  """
  @spec before(t, atom) :: t
  def before(pipeline, phase) do
    List.flatten(pipeline)
    |> Enum.take_while(&(!match_phase?(phase, &1)))
  end

  # Whether a phase configuration is for a given phase
  @spec match_phase?(Phase.t, phase_config_t) :: boolean
  defp match_phase?(phase, phase), do: true
  defp match_phase?(phase, {phase, _}), do: true
  defp match_phase?(_, _), do: false

  @doc """
  Return the part of a pipeline up to and including a specific phase.
  """
  @spec upto(t, atom) :: t
  def upto(pipeline, phase) do
    index = List.flatten(pipeline)
    |> Enum.find_index(&(match_phase?(phase, &1)))
    if index do
      Enum.take(pipeline, index + 1)
    else
      pipeline
    end
  end

  @bad_return "Phase did not return an {:ok, any} | {:error, %{errors: [Phase.Error.t]} | Phase.Error.t | String.t} tuple"

  @spec do_run(input_t, t) :: {:ok, output_t} | {:error, Phase.Error.t}
  defp do_run(input, pipeline) do
    List.flatten(pipeline)
    |> Enum.reduce_while(input, fn config, input ->
      {phase, args} = phase_invocation(config)
      case apply(phase, :run, [input | args]) do
        {:ok, value} ->
          {:cont, value}
        {:error, value} when is_binary(value) ->
          halt_with_error_result(phase, value)
        {:error, %Phase.Error{} = value} ->
          halt_with_error_result(phase, value)
        {:error, %{errors: _} = value} ->
          halt_with_error_result(phase, value)
        {:pipeline_error, message} ->
          {:halt, {:error, message}}
        _ ->
          {:halt, {:error, phase_error(phase, @bad_return)}}
      end
    end)
  end

  @spec halt_with_error_result(Phase.t, output_t | Phase.Error.t | [Phase.Error.t]) :: {:halt, {:ok, output_t}}
  defp halt_with_error_result(phase, error) do
    {:halt, {:ok, result_with_errors(phase, error)}}
  end

  @spec phase_invocation(phase_config_t) :: {Phase.t, list}
  defp phase_invocation({phase, args}) do
    {phase, List.wrap(args)}
  end
  defp phase_invocation(phase) do
    {phase, []}
  end

  @spec result_with_errors(Phase.t, output_t | Phase.Error.t | [Phase.Error.t]) :: output_t
  defp result_with_errors(_, %{errors: _} = result) do
    result
  end
  defp result_with_errors(phase, err) do
    Pipeline.ErrorResult.new(phase_error(phase, err))
  end

  @spec phase_error(Phase.t, Phase.Error.t | String.t) :: Phase.Error.t
  defp phase_error(_, %Phase.Error{} = err) do
    err
  end
  defp phase_error(phase, message) when is_binary(message) do
    %Phase.Error{
      message: message,
      phase: phase,
    }
  end

end
