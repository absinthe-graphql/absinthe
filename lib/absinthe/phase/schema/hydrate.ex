defmodule Absinthe.Phase.Schema.Hydrate do
  @moduledoc false
  @behaviour Absinthe.Schema.Hydrator

  use Absinthe.Phase
  alias Absinthe.Blueprint

  @hydrate [
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
    hydrator = Keyword.get(opts, :hydrator, __MODULE__)
    blueprint = Blueprint.prewalk(blueprint, &handle_node(&1, [], schema, hydrator))
    {:ok, blueprint}
  end

  defp handle_node(%Blueprint{} = node, ancestors, schema, hydrator) do
    node
    |> hydrate_node(ancestors, schema, hydrator)
    |> set_children(ancestors, schema, hydrator)
  end

  defp handle_node(%node_module{} = node, ancestors, schema, hydrator)
       when node_module in @hydrate do
    case Absinthe.Type.built_in_module?(node.module) do
      true ->
        {:halt, node}

      false ->
        node
        |> hydrate_node(ancestors, schema, hydrator)
        |> set_children(ancestors, schema, hydrator)
    end
  end

  defp handle_node(node, ancestors, schema, hydrator) do
    set_children(node, ancestors, schema, hydrator)
  end

  defp set_children(parent, ancestors, schema, hydrator) do
    Blueprint.prewalk(parent, fn
      ^parent -> parent
      child -> {:halt, handle_node(child, [parent | ancestors], schema, hydrator)}
    end)
  end

  defp hydrate_node(%{} = node, ancestors, schema, hydrator) do
    hydrations = schema.hydrate(node, ancestors)
    apply_hydrations(node, hydrations, hydrator)
  end

  defp apply_hydrations(node, hydrations, hydrator) do
    hydrations
    |> List.wrap()
    |> Enum.reduce(node, fn hydration, node ->
      hydrator.apply_hydration(node, hydration)
    end)
  end

  @impl Absinthe.Schema.Hydrator

  def apply_hydration(node, {:description, text}) do
    %{node | description: text}
  end

  def apply_hydration(node, {:resolve, resolver}) do
    %{node | middleware: [{Absinthe.Resolution, resolver}]}
  end

  def apply_hydration(node, {:resolve_type, resolve_type}) do
    %{node | resolve_type: resolve_type}
  end

  @hydration_level1 [
    Blueprint.Schema.DirectiveDefinition,
    Blueprint.Schema.EnumTypeDefinition,
    Blueprint.Schema.InputObjectTypeDefinition,
    Blueprint.Schema.InterfaceTypeDefinition,
    Blueprint.Schema.ObjectTypeDefinition,
    Blueprint.Schema.ScalarTypeDefinition,
    Blueprint.Schema.UnionTypeDefinition
  ]

  @hydration_level2 [
    Blueprint.Schema.FieldDefinition,
    Blueprint.Schema.EnumValueDefinition
  ]

  @hydration_level3 [
    Blueprint.Schema.InputValueDefinition
  ]

  def apply_hydration(%Absinthe.Blueprint{} = root, %{} = sub_hydrations) do
    {root, _} =
      Blueprint.prewalk(root, nil, fn
        %module{identifier: ident} = node, nil when module in @hydration_level1 ->
          case Map.fetch(sub_hydrations, ident) do
            :error ->
              {node, nil}

            {:ok, type_hydrations} ->
              {apply_hydrations(node, type_hydrations, __MODULE__), nil}
          end

        node, nil ->
          {node, nil}
      end)

    root
  end

  def apply_hydration(%module{} = root, %{} = sub_hydrations)
      when module in @hydration_level1 do
    {root, _} =
      Blueprint.prewalk(root, nil, fn
        %module{identifier: ident} = node, nil when module in @hydration_level2 ->
          case Map.fetch(sub_hydrations, ident) do
            :error ->
              {node, nil}

            {:ok, type_hydrations} ->
              {apply_hydrations(node, type_hydrations, __MODULE__), nil}
          end

        node, nil ->
          {node, nil}
      end)

    root
  end

  def apply_hydration(%module{} = root, %{} = sub_hydrations)
      when module in @hydration_level2 do
    {root, _} =
      Blueprint.prewalk(root, nil, fn
        %module{identifier: ident} = node, nil when module in @hydration_level3 ->
          case Map.fetch(sub_hydrations, ident) do
            :error ->
              {node, nil}

            {:ok, type_hydrations} ->
              {apply_hydrations(node, type_hydrations, __MODULE__), nil}
          end

        node, nil ->
          {node, nil}
      end)

    root
  end
end
