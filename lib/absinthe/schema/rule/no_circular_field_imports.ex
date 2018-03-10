defmodule Absinthe.Schema.Rule.NoCircularFieldImports do
  @moduledoc false
  # This has to be run prior to the module compilation, and is called
  # from Notation.Writer instead of Rule
  def check({definitions, errors}) do
    acc = []
    graph = :digraph.new([:acyclic])
    do_check(definitions, graph, errors, acc)
  end

  defp do_check([], graph, errors, acc) do
    :digraph.delete(graph)
    {:lists.reverse(acc), errors}
  end

  defp do_check([definition | rest], graph, errors, acc) do
    {acc, errors} =
      definition.attrs
      |> Keyword.get(:field_imports)
      |> case do
        [_ | _] = imports ->
          check_imports(definition, imports, graph, errors, acc)

        _ ->
          {[definition | acc], errors}
      end

    do_check(rest, graph, errors, acc)
  end

  defp check_imports(definition, imports, graph, errors, acc) do
    :digraph.add_vertex(graph, definition.identifier)

    Enum.reduce(imports, [], fn {ref, _}, errors ->
      :digraph.add_vertex(graph, ref)

      case :digraph.add_edge(graph, definition.identifier, ref) do
        {:error, {:bad_edge, path}} ->
          # All just error generation logic
          deps =
            [definition.identifier | path]
            |> Enum.map(&"`#{&1}'")
            |> Enum.join(" => ")

          msg =
            String.trim("""
            Field Import Cycle Error

            Field Import in object `#{definition.identifier}' `import_fields(#{inspect(ref)}) forms a cycle via: (#{
              deps
            })
            """)

          error = %{
            rule: __MODULE__,
            location: %{file: definition.file, line: definition.line},
            data: %{artifact: msg, value: ref}
          }

          [error | errors]

        _ ->
          errors
      end
    end)
    |> case do
      [] -> {[definition | acc], errors}
      new_errors -> {acc, new_errors ++ errors}
    end
  end
end
