defmodule Absinthe.Blueprint.Transform do
  @moduledoc false

  alias Absinthe.Blueprint

  @doc """
  Apply `fun` to a node, then walk to its children and do the same
  """
  @spec prewalk(
          Blueprint.node_t(),
          (Blueprint.node_t() -> Blueprint.node_t() | {:halt, Blueprint.node_t()})
        ) :: Blueprint.node_t()
  def prewalk(node, fun) when is_function(fun, 1) do
    {node, _} =
      prewalk(node, nil, fn x, nil ->
        case fun.(x) do
          {:halt, x} -> {:halt, x, nil}
          x -> {x, nil}
        end
      end)

    node
  end

  @doc """
  Same as `prewalk/2` but takes and returns an accumulator

  The supplied function must be arity 2.
  """
  @spec prewalk(
          Blueprint.node_t(),
          acc,
          (Blueprint.node_t(), acc ->
             {Blueprint.node_t(), acc} | {:halt, Blueprint.node_t(), acc})
        ) :: {Blueprint.node_t(), acc}
        when acc: var
  def prewalk(node, acc, fun) when is_function(fun, 2) do
    walk(node, acc, fun, &pass/2)
  end

  @doc """
  Apply `fun` to all children of a node, then apply `fun` to node
  """
  @spec postwalk(Blueprint.node_t(), (Blueprint.node_t() -> Blueprint.node_t())) ::
          Blueprint.node_t()
  def postwalk(node, fun) when is_function(fun, 1) do
    {node, _} = postwalk(node, nil, fn x, nil -> {fun.(x), nil} end)
    node
  end

  @doc """
  Same as `postwalk/2` but takes and returns an accumulator
  """
  @spec postwalk(Blueprint.node_t(), acc, (Blueprint.node_t(), acc -> {Blueprint.node_t(), acc})) ::
          {Blueprint.node_t(), acc}
        when acc: var
  def postwalk(node, acc, fun) when is_function(fun, 2) do
    walk(node, acc, &pass/2, fun)
  end

  defp pass(x, acc), do: {x, acc}

  nodes_with_children = %{
    Blueprint => [:fragments, :operations, :schema_definitions, :directives],
    Blueprint.Directive => [:arguments],
    Blueprint.Document.Field => [:selections, :arguments, :directives],
    Blueprint.Document.Operation => [:selections, :variable_definitions, :directives],
    Blueprint.TypeReference.List => [:of_type],
    Blueprint.TypeReference.NonNull => [:of_type],
    Blueprint.Document.Fragment.Inline => [:selections, :directives],
    Blueprint.Document.Fragment.Named => [:selections, :directives],
    Blueprint.Document.Fragment.Spread => [:directives],
    Blueprint.Document.VariableDefinition => [:type, :default_value, :directives],
    Blueprint.Input.Argument => [:input_value],
    Blueprint.Input.Field => [:input_value],
    Blueprint.Input.Object => [:fields],
    Blueprint.Input.List => [:items],
    Blueprint.Input.RawValue => [:content],
    Blueprint.Input.Value => [:normalized],
    Blueprint.Schema.DirectiveDefinition => [:directives, :arguments],
    Blueprint.Schema.EnumTypeDefinition => [:directives, :values],
    Blueprint.Schema.EnumValueDefinition => [:directives],
    Blueprint.Schema.FieldDefinition => [:type, :arguments, :directives],
    Blueprint.Schema.InputObjectTypeDefinition => [:fields, :directives],
    Blueprint.Schema.InputValueDefinition => [:type, :default_value, :directives],
    Blueprint.Schema.InterfaceTypeDefinition => [:interfaces, :fields, :directives],
    Blueprint.Schema.ObjectTypeDefinition => [:interfaces, :fields, :directives],
    Blueprint.Schema.ScalarTypeDefinition => [:directives],
    Blueprint.Schema.SchemaDefinition => [:directive_definitions, :type_definitions, :directives],
    Blueprint.Schema.UnionTypeDefinition => [:directives, :types]
  }

  @spec walk(
          Blueprint.node_t(),
          acc,
          (Blueprint.node_t(), acc ->
             {Blueprint.node_t(), acc} | {:halt, Blueprint.node_t(), acc}),
          (Blueprint.node_t(), acc -> {Blueprint.node_t(), acc})
        ) :: {Blueprint.node_t(), acc}
        when acc: var
  def walk(blueprint, acc, pre, post)

  def walk(nodes, acc, pre, post) when is_list(nodes) do
    Enum.map_reduce(nodes, acc, &walk(&1, &2, pre, post))
  end

  def walk(node, acc, pre, post) do
    {node, acc} =
      case pre.(node, acc) do
        {:halt, node, acc} ->
          {node, acc}

        {node, acc} ->
          maybe_walk_children(node, acc, pre, post)
      end

    post.(node, acc)
  end

  for {node_name, children} <- nodes_with_children do
    def maybe_walk_children(%unquote(node_name){} = node, acc, pre, post) do
      node_with_children(node, unquote(children), acc, pre, post)
    end
  end

  def maybe_walk_children(node, acc, _, _) do
    {node, acc}
  end

  defp node_with_children(node, children, acc, pre, post) do
    walk_children(node, children, acc, pre, post)
  end

  defp walk_children(node, children, acc, pre, post) do
    Enum.reduce(children, {node, acc}, fn child_key, {node, acc} ->
      {children, acc} =
        node
        |> Map.fetch!(child_key)
        |> walk(acc, pre, post)

      {Map.put(node, child_key, children), acc}
    end)
  end
end
