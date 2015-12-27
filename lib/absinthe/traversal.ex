defmodule Absinthe.Traversal do

  @moduledoc """
  Graph/Tree traversal utilities for dealing with ASTs and schemas using the
  `Absinthe.Traversal.Node` protocol.
  """

  alias __MODULE__
  alias Absinthe.Schema
  alias Absinthe.Traversal.Node

  @type t :: %{schema: Schema.t, seen: [Node.t], path: [Node.t]}
  defstruct schema: nil, seen: [], path: []

  @typedoc """
  Instructions defining behavior during traversal
  * `{:ok, value, schema}`: The value of the node is `value`, and traversal should continue to children (using `schema`)
  * `{:prune, value}`: The value of the node is `value` and traversal should NOT continue to children
  * `{:error, message}`: Bad stuff happened, explained by `message`
  """
  @type instruction_t :: {:ok, any} | {:prune, any} | {:error, any}

  @doc """
  Traverse, reducing nodes using a given function to evaluate their value.
  """
  @spec reduce(Node.t, Schema.tt, any, (Node.t -> instruction_t)) :: any
  def reduce(node, schema, initial_value, node_evaluator) do
    do_reduce(node, %Traversal{schema: schema}, initial_value, node_evaluator)
  end

  # Reduce using a traversal struct
  @spec do_reduce(Node.t, t, any, (Node.t -> instruction_t)) :: any
  defp do_reduce(node, traversal, initial_value, node_evaluator) do
    case node_evaluator.(node, traversal, initial_value) do
      {:ok, value, traversal_for_children} ->
        reduce_children(node, traversal_for_children, value, node_evaluator)
      {:prune, value, traversal_to_return} ->
        value
      {:error, _} = err ->
        IO.inspect(:got_err)
        err
    end
  end

  # Traverse a node's children
  @spec reduce(Node.t, t, any, (Node.t -> instruction_t)) :: any
  defp reduce_children(node, traversal, initial, node_evalator) do
    Enum.reduce(Node.children(node, traversal), initial, fn
      child, acc ->
        do_reduce(child, traversal, acc, node_evalator)
    end)
  end

end
