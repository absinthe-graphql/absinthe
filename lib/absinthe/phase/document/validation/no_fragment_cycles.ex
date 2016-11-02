defmodule Absinthe.Phase.Document.Validation.NoFragmentCycles do
  @moduledoc false

  # Ensure that document doesn't have any fragment cycles that could
  # result in a loop during execution.
  #
  # Note that if this phase fails, an error should immediately be given to
  # the user.

  alias Absinthe.{Blueprint, Phase}

  use Absinthe.Phase

  @doc """
  Run the validation.
  """
  @spec run(Blueprint.t, Keyword.t) :: Phase.result_t
  def run(input, options \\ []) do
    do_run(input, Map.new(options))
  end

  @spec do_run(Blueprint.t, %{validation_result_phase: Phase.t}) :: Phase.result_t
  def do_run(input, %{validation_result_phase: abort_phase}) do
    {fragments, error_count} = check(input.fragments)
    result = put_in(input.fragments, fragments)
    if error_count > 0 do
      {:jump, result, abort_phase}
    else
      {:ok, result}
    end
  end

  # Check a list of fragments for cycles
  @spec check([Blueprint.Document.Fragment.Named.t]) :: {[Blueprint.Document.Fragment.Named.t], integer}
  defp check(fragments) do
    {_, graph} = Blueprint.prewalk(fragments, :digraph.new([:cyclic]), &vertex/2)
    {modified, error_count} = Enum.reduce(fragments, {[], 0}, fn
      fragment, {processed, error_count} ->
        errors_to_add = cycle_errors(fragment, :digraph.get_cycle(graph, fragment.name))
        fragment_with_errors = update_in(fragment.errors, &(errors_to_add ++ &1))
        {[fragment_with_errors | processed], error_count + length(errors_to_add)}
    end)
    :digraph.delete(graph)
    {modified, error_count}
  end

  # Add a vertex modeling a fragment
  @spec vertex(Blueprint.Document.Fragment.Named.t, :digraph.graph) :: {Blueprint.Document.Fragment.Named.t, :digraph.graph}
  defp vertex(%Blueprint.Document.Fragment.Named{} = fragment, graph) do
    :digraph.add_vertex(graph, fragment.name)
    Enum.each(fragment.selections, fn
      %Blueprint.Document.Fragment.Spread{} = spread ->
        edge(fragment, spread, graph)
      _ ->
        false
    end)
    {fragment, graph}
  end
  defp vertex(fragment, graph) do
    {fragment, graph}
  end

  # Add an edge, modeling the relationship between two fragments
  @spec edge(Blueprint.Document.Fragment.Named.t, Blueprint.Document.Fragment.Spread.t, :digraph.graph) :: true
  defp edge(fragment, spread, graph) do
    :digraph.add_vertex(graph, spread.name)
    :digraph.add_edge(graph, fragment.name, spread.name)
    true
  end

  # Generate an error for a cyclic reference
  @spec cycle_errors(Blueprint.Document.Fragment.Named.t, false | [String.t]) :: [Phase.Error.t]
  defp cycle_errors(_, false) do
    []
  end
  defp cycle_errors(fragment, cycles) do
    [cycle_error(fragment, error_message(fragment.name, cycles))]
  end

  @doc """
  Generate the error message.
  """
  @spec error_message(String.t, [String.t]) :: String.t
  def error_message(fragment_name, [fragment_name]) do
    ~s(Cannot spread fragment "#{fragment_name}" within itself.)
  end
  def error_message(fragment_name, [_fragment_name | cycles]) do
    deps = Enum.map(cycles, &~s("#{&1}")) |> Enum.join(", ")
    ~s(Cannot spread fragment "#{fragment_name}" within itself via #{deps}.)
  end

  # Generate the error for a fragment cycle
  @spec cycle_error(Blueprint.Document.Fragment.Named.t, String.t) :: Phase.t
  defp cycle_error(fragment, message) do
    %Phase.Error{
      message: message,
      phase: __MODULE__,
      locations: [
        %{line: fragment.source_location.line, column: fragment.source_location.column}
      ],
    }
  end

end
