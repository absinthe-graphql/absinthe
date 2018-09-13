defmodule Absinthe.Phase.Schema.ValidateTypeReferences do

  @moduledoc false

  use Absinthe.Phase
  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Schema

  # TODO: actually do the type reference validation.
  # Right now it just handles topsorting the types by import
  def run(blueprint, _opts) do
    blueprint = Blueprint.prewalk(blueprint, &handle_imports/1)
    {:ok, blueprint}
  end

  def handle_imports(%Schema.SchemaDefinition{} = schema) do
    types = sort_and_validate_types(schema.type_definitions)

    {:halt, %{schema | type_definitions: types}}
  end

  def handle_imports(node), do: node

  def sort_and_validate_types(types) do
    graph = :digraph.new([:cyclic])

    try do
      _ = check(types, graph)
      for type <- types do
        if cycle = :digraph.get_cycle(graph, type.identifier) do
          raise "cycle! #{inspect cycle}"
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

  defp check(types, graph) do
    Enum.each(types, &add_to_graph(&1, graph))
  end

  defp add_to_graph(type, graph) do
    :digraph.add_vertex(graph, type.identifier)

    with %{imports: imports} <- type do
      for {ident, _} <- imports do
        :digraph.add_vertex(graph, ident)
        :digraph.add_edge(graph, type.identifier, ident)
      end
    end
  end
end
