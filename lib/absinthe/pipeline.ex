defmodule Absinthe.Pipeline do
  @moduledoc """
  Execute a pipeline of phases.

  A pipeline is merely a list of phases. This module contains functions for building,
  modifying, and executing pipelines of phases.
  """

  alias Absinthe.Phase

  require Logger

  @type data_t :: any

  @type phase_config_t :: Phase.t() | {Phase.t(), Keyword.t()}

  @type t :: [phase_config_t | [phase_config_t]]

  @spec run(data_t, t) :: {:ok, data_t, [Phase.t()]} | {:error, String.t(), [Phase.t()]}
  def run(input, pipeline) do
    pipeline
    |> List.flatten()
    |> run_phase(input)
  end

  @defaults [
    adapter: Absinthe.Adapter.LanguageConventions,
    operation_name: nil,
    variables: %{},
    context: %{},
    root_value: %{},
    validation_result_phase: Phase.Document.Validation.Result,
    result_phase: Phase.Document.Result,
    jump_phases: true
  ]

  def options(overrides \\ []) do
    Keyword.merge(@defaults, overrides)
  end

  @spec for_document(Absinthe.Schema.t()) :: t
  @spec for_document(Absinthe.Schema.t(), Keyword.t()) :: t
  def for_document(schema, options \\ []) do
    options = options(Keyword.put(options, :schema, schema))

    [
      # Parse Document
      {Phase.Parse, options},
      # Convert to Blueprint
      {Phase.Blueprint, options},
      # Find Current Operation (if any)
      {Phase.Document.Validation.ProvidedAnOperation, options},
      {Phase.Document.CurrentOperation, options},
      # Mark Fragment/Variable Usage
      Phase.Document.Uses,
      # Validate Document Structure
      {Phase.Document.Validation.NoFragmentCycles, options},
      Phase.Document.Validation.LoneAnonymousOperation,
      Phase.Document.Validation.SelectedCurrentOperation,
      Phase.Document.Validation.KnownFragmentNames,
      Phase.Document.Validation.NoUndefinedVariables,
      Phase.Document.Validation.NoUnusedVariables,
      # TODO: uncomment in 1.5
      # Phase.Document.Validation.NoUnusedFragments
      Phase.Document.Validation.UniqueFragmentNames,
      Phase.Document.Validation.UniqueOperationNames,
      Phase.Document.Validation.UniqueVariableNames,
      # Apply Input
      {Phase.Document.Context, options},
      {Phase.Document.Variables, options},
      Phase.Document.Validation.ProvidedNonNullVariables,
      Phase.Document.Arguments.Normalize,
      # Map to Schema
      {Phase.Schema, options},
      # Ensure Types
      Phase.Validation.KnownTypeNames,
      # Process Arguments
      Phase.Document.Arguments.CoerceEnums,
      Phase.Document.Arguments.CoerceLists,
      {Phase.Document.Arguments.Parse, options},
      Phase.Document.MissingVariables,
      Phase.Document.MissingLiterals,
      Phase.Document.Arguments.FlagInvalid,
      # Validate Full Document
      Phase.Validation.KnownDirectives,
      Phase.Document.Validation.ScalarLeafs,
      Phase.Document.Validation.VariablesAreInputTypes,
      Phase.Document.Validation.ArgumentsOfCorrectType,
      Phase.Document.Validation.KnownArgumentNames,
      Phase.Document.Validation.ProvidedNonNullArguments,
      Phase.Document.Validation.UniqueArgumentNames,
      Phase.Document.Validation.UniqueInputFieldNames,
      Phase.Document.Validation.FieldsOnCorrectType,
      Phase.Document.Validation.OnlyOneSubscription,
      # Check Validation
      {Phase.Document.Validation.Result, options},
      # Prepare for Execution
      Phase.Document.Arguments.Data,
      # Apply Directives
      Phase.Document.Directives,
      # Analyse Complexity
      {Phase.Document.Complexity.Analysis, options},
      {Phase.Document.Complexity.Result, options},
      # Execution
      {Phase.Subscription.SubscribeSelf, options},
      {Phase.Document.Execution.Resolution, options},
      # Format Result
      Phase.Document.Result
    ]
  end

  @defaults [
    adapter: Absinthe.Adapter.LanguageConventions
  ]

  @spec for_schema(nil | Absinthe.Schema.t()) :: t
  @spec for_schema(nil | Absinthe.Schema.t(), Keyword.t()) :: t
  def for_schema(prototype_schema, options \\ []) do
    options =
      @defaults
      |> Keyword.merge(Keyword.put(options, :schema, prototype_schema))

    [
      Phase.Parse,
      Phase.Blueprint,
      {Phase.Schema, options},
      Phase.Validation.KnownTypeNames,
      Phase.Validation.KnownDirectives
    ]
  end

  @doc """
  Return the part of a pipeline before a specific phase.
  """
  @spec before(t, atom) :: t
  def before(pipeline, phase) do
    result =
      List.flatten(pipeline)
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
    result =
      List.flatten(pipeline)
      |> Enum.drop_while(&(!match_phase?(phase, &1)))

    case result do
      [] ->
        raise RuntimeError, "Could not find phase #{phase}"

      _ ->
        result
    end
  end

  @doc """
  Replace a phase in a pipeline with another, supporting reusing the same
  options.

  ## Examples

  Replace a simple phase (without options):

      iex> Pipeline.replace([A, B, C], B, X)
      [A, X, C]

  Replace a phase with options, retaining them:

      iex> Pipeline.replace([A, {B, [name: "Thing"]}, C], B, X)
      [A, {X, [name: "Thing"]}, C]

  Replace a phase with options, overriding them:

      iex> Pipeline.replace([A, {B, [name: "Thing"]}, C], B, {X, [name: "Nope"]})
      [A, {X, [name: "Nope"]}, C]

  """
  @spec replace(t, Phase.t(), phase_config_t) :: t
  def replace(pipeline, phase, replacement) do
    Enum.map(pipeline, fn candidate ->
      case match_phase?(phase, candidate) do
        true ->
          case phase_invocation(candidate) do
            {_, []} ->
              replacement

            {_, opts} ->
              case is_atom(replacement) do
                true ->
                  {replacement, opts}

                false ->
                  replacement
              end
          end

        false ->
          candidate
      end
    end)
  end

  # Whether a phase configuration is for a given phase
  @spec match_phase?(Phase.t(), phase_config_t) :: boolean
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

  @spec without(t, Phase.t()) :: t
  def without(pipeline, phase) do
    pipeline
    |> Enum.filter(&(not match_phase?(phase, &1)))
  end

  @spec insert_before(t, Phase.t(), phase_config_t | [phase_config_t]) :: t
  def insert_before(pipeline, phase, additional) do
    beginning = before(pipeline, phase)
    beginning ++ List.wrap(additional) ++ (pipeline -- beginning)
  end

  @spec insert_after(t, Phase.t(), phase_config_t | [phase_config_t]) :: t
  def insert_after(pipeline, phase, additional) do
    beginning = upto(pipeline, phase)
    beginning ++ List.wrap(additional) ++ (pipeline -- beginning)
  end

  @spec reject(t, Regex.t() | (Module.t() -> boolean)) :: t
  def reject(pipeline, %Regex{} = pattern) do
    reject(pipeline, fn phase ->
      Regex.match?(pattern, Atom.to_string(phase))
    end)
  end

  def reject(pipeline, fun) do
    Enum.reject(pipeline, fn
      {phase, _} -> fun.(phase)
      phase -> fun.(phase)
    end)
  end

  @spec run_phase(t, data_t, [Phase.t()]) ::
          {:ok, data_t, [Phase.t()]} | {:error, String.t(), [Phase.t()]}
  def run_phase(pipeline, input, done \\ [])

  def run_phase([], input, done) do
    {:ok, input, done}
  end

  def run_phase([phase_config | todo], input, done) do
    {phase, options} = phase_invocation(phase_config)

    case phase.run(input, options) do
      {:ok, result} ->
        run_phase(todo, result, [phase | done])

      {:jump, result, destination_phase} when is_atom(destination_phase) ->
        run_phase(from(todo, destination_phase), result, [phase | done])

      {:insert, result, extra_pipeline} ->
        run_phase(List.wrap(extra_pipeline) ++ todo, result, [phase | done])

      {:swap, result, target, replacements} ->
        todo
        |> replace(target, replacements)
        |> run_phase(result, [phase | done])

      {:replace, result, final_pipeline} ->
        run_phase(List.wrap(final_pipeline), result, [phase | done])

      {:error, message} ->
        {:error, message, [phase | done]}

      _ ->
        {:error, "Last phase did not return a valid result tuple.", [phase | done]}
    end
  end

  @spec phase_invocation(phase_config_t) :: {Phase.t(), list}
  defp phase_invocation({phase, options}) when is_list(options) do
    {phase, options}
  end

  defp phase_invocation(phase) do
    {phase, []}
  end
end
