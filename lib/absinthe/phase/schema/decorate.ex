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

  def apply_decoration(
        node = %{fields: fields},
        {:add_fields, new_fields}
      )
      when is_list(new_fields) do
    new_fields = new_fields |> List.wrap()

    new_field_names = Enum.map(new_fields, & &1.name)

    filtered_fields =
      fields
      |> Enum.reject(fn %{name: field_name} -> field_name in new_field_names end)

    %{node | fields: filtered_fields ++ new_fields}
  end

  def apply_decoration(
        node = %{fields: fields},
        {:del_fields, del_field_name}
      ) do
    filtered_fields =
      fields
      |> Enum.reject(fn %{name: field_name} -> field_name == del_field_name end)

    %{node | fields: filtered_fields}
  end

  @decoration_level1 [
    Blueprint.Schema.DirectiveDefinition,
    Blueprint.Schema.EnumTypeDefinition,
    Blueprint.Schema.InputObjectTypeDefinition,
    Blueprint.Schema.InterfaceTypeDefinition,
    Blueprint.Schema.ObjectTypeDefinition,
    Blueprint.Schema.ScalarTypeDefinition,
    Blueprint.Schema.UnionTypeDefinition
  ]

  @decoration_level2 [
    Blueprint.Schema.FieldDefinition,
    Blueprint.Schema.EnumValueDefinition
  ]

  @decoration_level3 [
    Blueprint.Schema.InputValueDefinition
  ]

  def apply_decoration(%Absinthe.Blueprint{} = root, %{} = sub_decorations) do
    {root, _} =
      Blueprint.prewalk(root, nil, fn
        %module{identifier: ident} = node, nil when module in @decoration_level1 ->
          case Map.fetch(sub_decorations, ident) do
            :error ->
              {node, nil}

            {:ok, type_decorations} ->
              {apply_decorations(node, type_decorations, __MODULE__), nil}
          end

        node, nil ->
          {node, nil}
      end)

    root
  end

  def apply_decoration(%module{} = root, %{} = sub_decorations)
      when module in @decoration_level1 do
    {root, _} =
      Blueprint.prewalk(root, nil, fn
        %module{identifier: ident} = node, nil when module in @decoration_level2 ->
          case Map.fetch(sub_decorations, ident) do
            :error ->
              {node, nil}

            {:ok, type_decorations} ->
              {apply_decorations(node, type_decorations, __MODULE__), nil}
          end

        node, nil ->
          {node, nil}
      end)

    root
  end

  def apply_decoration(%module{} = root, %{} = sub_decorations)
      when module in @decoration_level2 do
    {root, _} =
      Blueprint.prewalk(root, nil, fn
        %module{identifier: ident} = node, nil when module in @decoration_level3 ->
          case Map.fetch(sub_decorations, ident) do
            :error ->
              {node, nil}

            {:ok, type_decorations} ->
              {apply_decorations(node, type_decorations, __MODULE__), nil}
          end

        node, nil ->
          {node, nil}
      end)

    root
  end
end
