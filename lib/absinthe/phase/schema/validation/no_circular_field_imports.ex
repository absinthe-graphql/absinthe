defmodule Absinthe.Phase.Schema.Validation.NoCircularFieldImports do
  @moduledoc false

  use Absinthe.Phase
  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Schema

  def run(blueprint, _opts) do
    blueprint = Blueprint.prewalk(blueprint, &validate_schema/1)
    {:ok, blueprint}
  end

  def validate_schema(%Schema.SchemaDefinition{type_definitions: types} = schema) do
    {:halt, %{schema | type_definitions: validate_cycles(types)}}
  end

  def validate_schema(node), do: node

  def validate_cycles(types) do
    graph = :digraph.new([:cyclic])

    try do
      _ = build_import_graph(types, graph)

      Enum.map(types, fn type ->
        if cycle = :digraph.get_cycle(graph, type.identifier) do
          type |> put_error(error(type, cycle))
        else
          type
        end
      end)
    after
      :digraph.delete(graph)
    end
  end

  defp error(type, deps) do
    %Absinthe.Phase.Error{
      message:
        String.trim("""
        Field Import Cycle Error

        Field Import in object `#{type.identifier}' `import_fields(#{inspect(type.imports)}) forms a cycle via: (#{inspect(deps)})
        """),
      locations: [type.__reference__.location],
      phase: __MODULE__,
      extra: type.identifier
    }
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
