defmodule Absinthe.Validation.PreventCircularFragments do
  alias Absinthe.{Language, Traversal}

  @moduledoc false

  def validate(doc, {_, errors}) do
    doc.definitions
    |> Enum.filter(fn
      %Language.Fragment{} -> true
      _ -> false
    end)
    |> check
  end

  def check(fragments) do
    fragments
    |> Enum.reduce({[], %{}}, fn fragment, acc ->
      check_fragment(fragment, acc)
    end)
    |> case do
      {[], _} -> {:ok, []}
      {errors, _} -> {:error, errors}
    end
  end

  # For a given fragment, determine if it forms a cycle.
  # Acc consists of a list of errors, and a map associating a given fragment name
  # with the names of other fragments it depends on internally via FragmentSpreads.
  defp check_fragment(fragment, acc) do
    result = Traversal.reduce(fragment, :unused, acc, fn
      %Language.FragmentSpread{} = spread, traversal, {errors, fragments} = acc ->
        transitive_fragments = transitive_dependencies(fragments, spread.name)

        dependencies = [spread.name | transitive_fragments]

        fragments = Map.update(fragments, fragment.name, dependencies, &(dependencies ++ &1))

        case fragment.name in dependencies do
          true ->
            # All just error generation logic
            deps = [fragment.name | dependencies]
            |> Enum.map(&"`#{&1}'")
            |> Enum.join(" => ")

            message = """
            Fragment Cycle Error

            Fragment `#{fragment.name}' forms a cycle via: (#{deps})
            """
            error = %{
              message: message,
              locations: [%{line: spread.loc.start_line, column: 0}]
            }
            {:ok, {[error | errors], fragments}, traversal}

          false ->
            {:ok, {errors, fragments}, traversal}
        end
      other, traversal, acc ->
        {:ok, acc, traversal}
    end)
  end

  # Suppose we already know that Fragment B depends on fragment C because
  # that was accumulated in a previous check_fragment call.
  #
  # If we now are checking fragment A, and have a node referring to
  # fragment B, we know that fragment A must transitively depend on all of
  # B's dependencies. This helps us capture cycles that happen over several
  # different fragments.
  defp transitive_dependencies(fragments, spread_name) do
    deps = fragments |> Map.get(spread_name, [])

    # this reversing stuff is to solve the dual constraints of keeping the
    # accumulator on the correct side of the ++, and to ensure that the
    # dependency order stays correct for nice error messages
    deps
    |> Enum.reduce(Enum.reverse(deps), fn dep, deps ->
      transitive_deps = fragments
      |> Map.get(dep, [])
      |> Enum.reverse

      transitive_deps ++ deps
    end)
    |> Enum.reverse
  end
end
