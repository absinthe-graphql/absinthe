defmodule Absinthe.Phase.Document.Validation.NoFragmentCycles do

  alias Absinthe.{Blueprint, Phase}

  use Absinthe.Phase

  @spec run(Blueprint.t) :: Phase.result_t
  def run(input) do
    {fragments, error_count} = check(input.fragments)
    {
      instruction(error_count),
      put_in(input.fragments, fragments)
    }
  end

  defp instruction(0), do: :ok
  defp instruction(_), do: :error

  @spec check([Blueprint.Document.Fragment.Named.t]) :: {[Blueprint.Document.Fragment.Named.t], integer}
  def check(fragments) do
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
  defp cycle_errors(fragment, [_]) do
    [cycle_error(fragment, "forms a cycle with itself")]
  end
  defp cycle_errors(fragment, cycle) do
    deps = Enum.map(cycle, &"`#{&1}'")
    |> Enum.join(" => ")
    [cycle_error(fragment, "forms a cycle via: (#{deps})")]
  end

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
