defmodule Absinthe.Phase.Document.Validation.NoIntrospection do
  @moduledoc false

  # Ensure that document doesn't have any of the specified types
  # defaulting to __schema and __type
  #
  
  use Absinthe.Phase
  use Absinthe.Phase.Validation

  @default_types [:__schema, :__type]
  
  @doc """
  Run the validation.
  """
  @spec run(Blueprint.t, Keyword.t) :: Phase.result_t
  def run(input, opts \\ []) do
    excluded_types = Keyword.get(opts, :exclude, @default_types)

    result = Blueprint.prewalk(input, &handle_node(&1, input.schema, excluded_types))
    {:ok, result}
  end

  # Check a node for introspection types
  defp handle_node(%{schema_node: nil} = node, _schema, _), do: {:halt, node}
  defp handle_node(%{schema_node: %{type: type}} = node, _, excluded_types) do
    if type in excluded_types do
      invalid_node(node, type)
    else
      node
    end
  end

  defp handle_node(node, _, _), do: node

  defp invalid_node(node, type) do
    node
    |> flag_invalid(:introspection_not_permitted)
    |> put_error(error(node, type))
  end

  # Generate the Error
  @spec error(Blueprint.Document.Field.t, String.t) :: Phase.Error.t
  defp error(node, type) do
    Phase.Error.new(
    __MODULE__,
    "Introspection is disabled, found #{type} in query.",
    location: node.source_location)
  end
end
