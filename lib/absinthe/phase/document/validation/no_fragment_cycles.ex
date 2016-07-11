defmodule Absinthe.Phase.Document.Validation.NoFragmentCycles do

  alias Absinthe.{Blueprint, Phase}

  use Absinthe.Phase

  @spec run(Blueprint.t, Keyword.t) :: {:ok, Blueprint.t}
  def run(input, _) do
    {
      :ok,
      put_in(input.fragments, check(input.fragments))
    }
  end

  @spec check([Blueprint.Document.Fragment.Named.t]) :: [Blueprint.Document.Fragment.Named.t]
  def check(fragments) do
    {result, graph} = Blueprint.prewalk(fragments, :digraph.new([:acyclic]), &vertex/2)
    # The table will get deleted when the process exits, but we might
    # as well clean up for ourselves explicitly.
    :digraph.delete(graph)
    result
  end

  @spec vertex(Blueprint.Document.Fragment.Named.t, :digraph.graph) :: {Blueprint.Document.Fragment.Named.t, :digraph.graph}
  defp vertex(fragment, graph) do
    :digraph.add_vertex(graph, fragment.name)
    result = Enum.reduce(fragment.selections, fragment, fn
      %Blueprint.Document.Fragment.Spread{} = spread, frag ->
        edge(frag, spread, graph)
      _, frag ->
        frag
    end)

    {result, graph}
  end

  @spec edge(Blueprint.Document.Fragment.Named.t, Blueprint.Document.Fragment.Spread.t, [String.t]) :: Blueprint.Document.Fragment.Named.t
  defp edge(fragment, spread, graph) do
    :digraph.add_vertex(graph, spread.name)
    case :digraph.add_edge(graph, fragment.name, spread.name) do
      {:error, {:bad_edge, path}} ->
        update_in(fragment.errors, &[error(fragment, spread, path) | &1])
      _ ->
        fragment
    end
  end

  # Generate an error for a cyclic reference
  @spec error(Blueprint.Document.Fragment.Named.t, Blueprint.Document.Fragment.Spread.t, [String.t]) :: Phase.Error.t
  defp error(fragment, spread, cycle) do
    deps = [fragment.name | cycle]
    |> Enum.map(&"`#{&1}'")
    |> Enum.join(" => ")
    %Phase.Error{
      message: "forms a cycle via: (#{deps})",
      phase: __MODULE__,
      locations: [
        %{line: spread.source_location.line, column: spread.source_location.column}
      ],
    }
  end

end
