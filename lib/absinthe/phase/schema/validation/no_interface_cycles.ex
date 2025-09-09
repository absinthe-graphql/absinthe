defmodule Absinthe.Phase.Schema.Validation.NoInterfaceCycles do
  @moduledoc false

  use Absinthe.Phase
  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Schema

  def run(blueprint, _opts) do
    blueprint = check(blueprint)

    {:ok, blueprint}
  end

  defp check(blueprint) do
    graph = :digraph.new([:cyclic])

    try do
      _ = build_interface_graph(blueprint, graph)

      Blueprint.prewalk(blueprint, &validate_schema(&1, graph))
    after
      :digraph.delete(graph)
    end
  end

  defp validate_schema(%Schema.InterfaceTypeDefinition{} = interface, graph) do
    if cycle = :digraph.get_cycle(graph, interface.identifier) do
      interface |> put_error(error(interface, cycle))
    else
      interface
    end
  end

  defp validate_schema(node, _graph) do
    node
  end

  defp build_interface_graph(blueprint, graph) do
    _ = Blueprint.prewalk(blueprint, &vertex(&1, graph))
  end

  defp vertex(%Schema.InterfaceTypeDefinition{} = implementor, graph) do
    :digraph.add_vertex(graph, implementor.identifier)

    for interface <- implementor.interfaces do
      edge(implementor, interface, graph)
    end

    implementor
  end

  defp vertex(implementor, _graph) do
    implementor
  end

  # Add an edge, modeling the relationship between two interfaces
  defp edge(implementor, interface, graph) do
    :digraph.add_vertex(graph, interface)

    :digraph.add_edge(graph, implementor.identifier, interface)

    true
  end

  defp error(type, deps) do
    %Absinthe.Phase.Error{
      message:
        String.trim("""
        Interface Cycle Error

        Interface `#{type.identifier}' forms a cycle via: (#{inspect(deps)})
        """),
      locations: [type.__reference__.location],
      phase: __MODULE__,
      extra: type.identifier
    }
  end
end
