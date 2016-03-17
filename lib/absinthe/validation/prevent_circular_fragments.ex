defmodule Absinthe.Validation.PreventCircularFragments do
  alias Absinthe.{Language, Traversal}

  @moduledoc false

  def validate(doc, {_, errors}) do
    doc.definitions
    |> Enum.filter(fn
      %Language.Fragment{} -> true
      _ -> false
    end)
    |> check(errors)
  end

  # The overall approach here is to create a digraph with an `acyclic`
  # constraint. Then we just add the fragments as vectors, and fragment
  # spreads are used to create edges. If at any point :digraph returns
  # an error we have a cycle! Thank you :digraph for doing the hard part
  # :)
  # NOTE: `:digraph` is MUTABLE, as it's backed by `:ets`
  def check(fragments, errors) do
    graph = :digraph.new([:acyclic])

    result = fragments
    |> Enum.reduce({errors, graph}, &check_fragment/2)
    |> case do
      {[], _} -> {:ok, []}
      {errors, _} -> {:error, errors}
    end

    # The table will get deleted when the process exits, but we might
    # as well clean up for ourselves explicitly.
    :digraph.delete(graph)

    result
  end

  def check([], errors, _), do: errors
  def check_fragment(fragment, {errors, graph}) do
    _ = :digraph.add_vertex(graph, fragment.name)

    Traversal.reduce(fragment, :unused, {errors, graph}, fn
      %Language.FragmentSpread{} = spread, traversal, {errors, graph} ->
        _ = :digraph.add_vertex(graph, spread.name)

        case :digraph.add_edge(graph, fragment.name, spread.name) do
          {:error, {:bad_edge, path}} ->
            # All just error generation logic
            deps = [fragment.name | path]
            |> Enum.map(&"`#{&1}'")
            |> Enum.join(" => ")

            msg = """
            Fragment Cycle Error

            Fragment `#{fragment.name}' forms a cycle via: (#{deps})
            """

            error = %{
              message: String.strip(msg),
              locations: [%{line: spread.loc.start_line, column: 0}]
            }

            {:ok, {[error | errors], graph}, traversal}

          _ ->
            {:ok, {errors, graph}, traversal}
        end
      _, traversal, acc ->
        {:ok, acc, traversal}
    end)
  end
end
