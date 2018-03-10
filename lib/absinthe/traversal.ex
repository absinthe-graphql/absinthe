defmodule Absinthe.Traversal do
  # Graph traversal utilities for dealing with ASTs and schemas using the
  # `Absinthe.Traversal.Node` protocol.
  # Note this really only exists to handle some Schema rules stuff and is generally
  # considered legacy code. See `Absinthe.Blueprint.Transform` for information
  # on how to walk blueprint trees.

  @moduledoc false

  alias __MODULE__
  alias Absinthe.Traversal.Node

  @type t :: %__MODULE__{context: any, seen: [Node.t()], path: [Node.t()]}
  defstruct context: nil, seen: [], path: []

  # Instructions defining behavior during traversal
  # * `{:ok, value, traversal}`: The value of the node is `value`, and traversal
  #   should continue to children (using `traversal`)
  # * `{:prune, value, traversal}`: The value of the node is `value` and
  #   traversal should NOT continue to children, but to siblings (using
  #   `traversal`)
  # * `{:error, message}`: Bad stuff happened, explained by `message`
  @type instruction_t :: {:ok, any, t} | {:prune, any, t} | {:error, any}

  # Traverse, reducing nodes using a given function to evaluate their value.
  @doc false
  @spec reduce(Node.t(), any, acc, (Node.t(), t, acc -> instruction_t)) :: acc when acc: var
  def reduce(node, context, initial_value, node_evaluator) do
    {result, _traversal} =
      do_reduce(node, %Traversal{context: context}, initial_value, node_evaluator)

    result
  end

  # Reduce using a traversal struct
  @spec do_reduce(Node.t(), t, acc, (Node.t(), t, acc -> instruction_t)) :: {acc, t} when acc: var
  defp do_reduce(node, traversal, initial_value, node_evaluator) do
    if seen?(traversal, node) do
      {initial_value, traversal}
    else
      case node_evaluator.(node, traversal, initial_value) do
        {:ok, value, next_traversal} ->
          reduce_children(node, next_traversal |> put_seen(node), value, node_evaluator)

        {:prune, value, next_traversal} ->
          {value, next_traversal |> put_seen(node)}
      end
    end
  end

  # Traverse a node's children
  @spec reduce_children(Node.t(), t, acc, (Node.t(), t, acc -> instruction_t)) :: {acc, t}
        when acc: var
  defp reduce_children(node, traversal, initial, node_evalator) do
    Enum.reduce(Node.children(node, traversal), {initial, traversal}, fn child,
                                                                         {this_value,
                                                                          this_traversal} ->
      do_reduce(child, this_traversal, this_value, node_evalator)
    end)
  end

  @spec seen?(t, Node.t()) :: boolean
  defp seen?(traversal, node), do: traversal.seen |> Enum.member?(node)

  @spec put_seen(t, Node.t()) :: t
  defp put_seen(traversal, node) do
    %{traversal | seen: [node | traversal.seen]}
  end
end
