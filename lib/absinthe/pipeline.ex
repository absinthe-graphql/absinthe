defmodule Absinthe.Pipeline do

  alias Absinthe.Phase
  alias __MODULE__

  require Logger

  @type data_t :: any

  @type phase_config_t :: Phase.t | {Phase.t, [any]}

  @type t :: [phase_config_t | [phase_config_t]]

  @spec run(data_t, t) :: {:ok, data_t, [Phase.t]} | {:error, String.t, [Phase.t]}
  def run(input, pipeline) do
    List.flatten(pipeline)
    |> run_phase(input)
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
      Phase.Document.Validation.Result,
      Phase.Document.Directives,
      Phase.Document.CascadeInvalid,
      Phase.Document.Flatten,
      {Phase.Document.Execution.Resolution, [context, root_value]},
      Phase.Debug,
      Phase.Document.Result
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
    result = List.flatten(pipeline)
    |> Enum.take_while(&(!match_phase?(phase, &1)))
    case result do
      ^pipeline ->
        raise RuntimeError, "Could not find phase #{phase}"
      _ ->
        result
    end
  end

  @doc """
  Return the part of a pipeline after (and including) a specific phase.
  """
  @spec from(t, atom) :: t
  def from(pipeline, phase) do
    result = List.flatten(pipeline)
    |> Enum.drop_while(&(!match_phase?(phase, &1)))
    case result do
      [] ->
        raise RuntimeError, "Could not find phase #{phase}"
      _ ->
        result
    end
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
    beginning = before(pipeline, phase)
    item = get_in(pipeline, [Access.at(length(beginning))])
    beginning ++ [item]
  end

  def insert_before(pipeline, phase, additional) do
    beginning = before(pipeline, phase)
    beginning ++ [additional] ++ (pipeline -- beginning)
  end

  @spec run_phase(t, data_t, [Phase.t]) :: {:ok, data_t, [Phase.t]} | {:error, String.t, [Phase.t]}
  defp run_phase(pipeline, input, done \\ [])
  defp run_phase([], input, done) do
    {:ok, input, done}
  end
  defp run_phase([phase_config | todo], input, done) do
    {phase, args} = phase_invocation(phase_config)
    case apply(phase, :run, [input | args]) do
      {:ok, result} ->
        run_phase(todo, result, [phase | done])
      {:jump, result, destination_phase} ->
        run_phase(from(todo, destination_phase), result, [phase | done])
      {:insert, result, extra_pipeline} ->
        run_phase(List.wrap(extra_pipeline) ++ todo, result, [phase | done])
      {:replace, result, final_pipeline} ->
        run_phase(List.wrap(final_pipeline), result, [phase | done])
      {:error, message} = err ->
        {:error, message, [phase | done]}
      _ ->
        {:error, "Last phase did not return a valid result tuple.", [phase | done]}
    end
  end

  @spec phase_invocation(phase_config_t) :: {Phase.t, list}
  defp phase_invocation({phase, args}) do
    {phase, List.wrap(args)}
  end
  defp phase_invocation(phase) do
    {phase, []}
  end

end
