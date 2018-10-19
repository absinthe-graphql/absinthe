defmodule Absinthe.Phase.Schema.Validation.NoCircularFieldImports do
  # types = sort_and_validate_types(types)
  use Absinthe.Phase
  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Schema

  #   deps =
  #   [definition.identifier | path]
  #   |> Enum.map(&"`#{&1}'")
  #   |> Enum.join(" => ")

  # msg =
  #   String.trim("""
  #   Field Import Cycle Error

  #   Field Import in object `#{definition.identifier}' `import_fields(#{inspect(ref)}) forms a cycle via: (#{
  #     deps
  #   })
  #   """)

  def run(blueprint, _opts) do
    blueprint = Blueprint.prewalk(blueprint, &validate_schema/1)
    {:ok, blueprint}
  end

  def validate_schema(%Schema.SchemaDefinition{type_definitions: types} = schema) do
    {:halt, %{schema | type_definitions: sort_and_validate_types(types)}}
  end

  def validate_schema(node), do: node

  def sort_and_validate_types(types) do
    graph = :digraph.new([:cyclic])

    try do
      _ = build_import_graph(types, graph)

      for type <- types do
        if cycle = :digraph.get_cycle(graph, type.identifier) do
          raise "cycle! #{inspect(cycle)}"
        end
      end

      types = Map.new(types, &{&1.identifier, &1})

      graph
      |> :digraph_utils.topsort()
      |> Enum.reverse()
      |> Enum.map(&Map.fetch!(types, &1))
    after
      :digraph.delete(graph)
    end
  end

  defp build_import_graph(types, graph) do
    Enum.each(types, &add_to_graph(&1, graph))
  end

  defp add_to_graph(type, graph) do
    :digraph.add_vertex(graph, type.identifier)

    with %{imports: imports} <- type do
      for {ident, _} <- imports do
        :digraph.add_vertex(graph, ident)

        case :digraph.add_edge(graph, type.identifier, ident) do
          {:error, _} ->
            raise "edge failed"

          _ ->
            :ok
        end
      end
    end
  end
end
