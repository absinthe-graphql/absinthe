defmodule Absinthe.Traversal do

  alias Absinthe.Schema
  alias Absinthe.Traversal.Node


  @typedoc """
  Instructions defining behavior during traversal
  * `{:ok, value}`: The value of the node is `value`, and traversal should continue to children
  * `{:prune, value}`: The value of the node is `value` and traversal should NOT continue to children
  * `{:error, message}`: Bad stuff happened, explained by `message`
  """
  @type instruction_t :: {:ok, any} | {:prune, any} | {:error, any}

  @doc """
  Traverse, reducing nodes using a given function to evaluate their value.
  """
  @spec reduce(Node.t, Schema.t, any, (Node.t -> instruction_t)) :: any
  def reduce(node, schema, initial_value, node_evalator) do
    case node_evalator.(node, schema, initial_value) do
      {:ok, value} ->
        reduce_children(node, schema, value, node_evalator)
      {:prune, value} ->
        value
      {:error, _} = err ->
        err
    end
  end

  defp reduce_children(node, schema, initial, node_evalator) do
    Enum.reduce(Node.children(node, schema), initial, fn
      child, acc ->
        reduce(child, schema, acc, node_evalator)
    end)
  end

end
