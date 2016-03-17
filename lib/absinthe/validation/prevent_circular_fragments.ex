defmodule Absinthe.Validation.PreventCircularFragments do
  alias Absinthe.{Language, Traversal}

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

  defp check_fragment(fragment, acc) do
    result = Traversal.reduce(fragment, :unused, acc, fn
      %Language.FragmentSpread{name: name}, traversal, {errors, fragments} = acc ->
        transitive_fragments = Map.get(fragments, name, [])

        dependencies = [name | transitive_fragments]

        fragments = Map.update(fragments, fragment.name, dependencies, &(dependencies ++ &1))

        case fragment.name in dependencies do
          true ->
            deps = [fragment.name | dependencies]
            |> Enum.map(&"`#{&1}'")
            |> Enum.join(" => ")

            error = """
            Fragment Cycle Error

            Fragment `#{fragment.name}' forms a cycle via: (#{deps})
            """
            {:ok, {[error | errors], fragments}, traversal}

          false ->
            {:ok, {errors, fragments}, traversal}
        end
      other, traversal, acc ->
        {:ok, acc, traversal}
    end)
  end
end
