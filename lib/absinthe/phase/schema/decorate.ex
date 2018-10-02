defmodule Absinthe.Phase.Schema.Decorate do
  @moduledoc false
  @behaviour __MODULE__.Decorator

  use Absinthe.Phase
  alias Absinthe.Blueprint

  @decorate [
    Blueprint.Schema.DirectiveDefinition,
    Blueprint.Schema.EnumTypeDefinition,
    Blueprint.Schema.EnumValueDefinition,
    Blueprint.Schema.FieldDefinition,
    Blueprint.Schema.InputObjectTypeDefinition,
    Blueprint.Schema.InputValueDefinition,
    Blueprint.Schema.InterfaceTypeDefinition,
    Blueprint.Schema.ObjectTypeDefinition,
    Blueprint.Schema.ScalarTypeDefinition,
    Blueprint.Schema.SchemaDefinition,
    Blueprint.Schema.UnionTypeDefinition
  ]

  @impl Absinthe.Phase
  def run(blueprint, opts \\ []) do
    {:ok, schema} = Keyword.fetch(opts, :schema)
    decorator = Keyword.get(opts, :decorator, __MODULE__)
    blueprint = Blueprint.prewalk(blueprint, &handle_node(&1, [], schema, decorator))
    {:ok, blueprint}
  end

  defp handle_node(%Blueprint{} = node, ancestors, schema, decorator) do
    node
    |> decorate_node(ancestors, schema, decorator)
    |> set_children(ancestors, schema, decorator)
  end

  defp handle_node(%node_module{} = node, ancestors, schema, decorator)
       when node_module in @decorate do
    case Absinthe.Type.built_in_module?(node.module) do
      true ->
        {:halt, node}

      false ->
        node
        |> decorate_node(ancestors, schema, decorator)
        |> set_children(ancestors, schema, decorator)
    end
  end

  defp handle_node(node, ancestors, schema, decorator) do
    set_children(node, ancestors, schema, decorator)
  end

  defp set_children(parent, ancestors, schema, decorator) do
    Blueprint.prewalk(parent, fn
      ^parent -> parent
      child -> {:halt, handle_node(child, [parent | ancestors], schema, decorator)}
    end)
  end

  defp decorate_node(%{} = node, ancestors, schema, decorator) do
    decorations = schema.decorations(node, ancestors)
    apply_decorations(node, decorations, decorator)
  end

  defp decorate_node(node, _ancestors, _schema, _decorator) do
    node
  end

  defp apply_decorations(node, decorations, decorator) do
    decorations
    |> List.wrap()
    |> Enum.reduce(node, fn decoration, node ->
      decorator.apply_decoration(node, decoration)
    end)
  end

  @impl __MODULE__.Decorator
  def apply_decoration(node, {:description, text}) do
    %{node | description: text}
  end

  def apply_decoration(node, {:resolve, resolver}) do
    %{node | middleware: [{Absinthe.Resolution, resolver}]}
  end
end
