defmodule Absinthe.Blueprint.Mapper do

  alias Absinthe.Blueprint

  @doc """
  Apply `fun` to a node, then walk to its children and do the same
  """
  @spec prewalk(Blueprint.t, (Blueprint.t -> Blueprint.t)) :: Blueprint.t
  def prewalk(node, fun) when is_function(fun, 1) do
    {node, _} = prewalk(node, nil, fn x, nil -> {fun.(x), nil} end)
    node
  end

  @doc """
  Same as `prewalk/2` but takes and returns an accumulator

  The supplied function must be arity 2.
  """
  @spec prewalk(Blueprint.t, any, ((Blueprint.t, any) -> {Blueprint.t, any})) :: {Blueprint.t, any}
  def prewalk(node, acc, fun) when is_function(fun, 2) do
    walk(node, acc, fun, fn x, acc -> {x, acc} end)
  end

  @doc """
  Apply `fun` to all children of a node, then apply `fun` to node
  """
  @spec prewalk(Blueprint.t, (Blueprint.t -> Blueprint.t)) :: Blueprint.t
  def postwalk(node, fun) when is_function(fun, 1) do
    {node, _} = postwalk(node, nil, fn x, nil -> {fun.(x), nil} end)
    node
  end

  @doc """
  Same as `postwalk/2` but takes and returns an accumulator
  """
  @spec prewalk(Blueprint.t, any, ((Blueprint.t, any) -> {Blueprint.t, any})) :: {Blueprint.t, any}
  def postwalk(node, acc, fun) when is_function(fun, 2) do
    walk(node, acc, fn x, acc -> {x, acc} end, fun)
  end

  nodes_with_children = %{
    Blueprint => [:operations, :types, :directives],
    Blueprint.Directive => [:arguments],
    Blueprint.Field => [:fields, :arguments, :directives],
    Blueprint.Operation => [:fields, :variable_definitions],
    Blueprint.ListType => [:of_type],
    Blueprint.NonNullType => [:of_type],
    Blueprint.VariableDefinition => [:type, :default_value],
    Blueprint.Input.Argument => [:value],
    Blueprint.Input.Field => [:value],
    Blueprint.Input.List => [:values],
    Blueprint.Input.Object => [:fields],
  }

  @spec walk(Blueprint.t, any, ((Blueprint.t, any) -> {Blueprint.t, any}), ((Blueprint.t, any) -> {Blueprint.t, any})) :: {Blueprint.t, any}
  def walk(blueprint, acc, pre, post)

  for {node_name, children} <- nodes_with_children do
    def walk(%unquote(node_name){} = node, acc, pre, post) do
      node_with_children(node, unquote(children), acc, pre, post)
    end
  end

  def walk(nodes, acc, pre, post) when is_list(nodes) do
    Enum.map_reduce(nodes, acc, &walk(&1, &2, pre, post))
  end
  def walk(leaf_node, acc, pre, post) do
    {leaf_node, acc} = pre.(leaf_node, acc)
    post.(leaf_node, acc)
  end

  defp node_with_children(node, children, acc, pre, post) do
    {node, acc} = pre.(node, acc)
    {node, acc} = walk_children(node, children, acc, pre, post)
    post.(node, acc)
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
