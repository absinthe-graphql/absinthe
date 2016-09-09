defmodule Absinthe.Phase.Document.Validation.KnownArgumentNames do
  @moduledoc """
  Validates document to ensure that all arguments are in the schema.

  Note: while graphql-js doesn't add errors to unknown arguments that
  are provided to unknown fields, Absinthe does -- but when the errors
  are harvested from the Blueprint tree, only the first layer of unknown
  errors (eg, the field) should be presented to the user.
  """

  alias Absinthe.{Blueprint, Phase}

  use Absinthe.Phase

  @doc """
  Run the validation.
  """
  @spec run(Blueprint.t) :: Phase.result_t
  def run(input) do
    result = Blueprint.prewalk(input, &handle_node/1)
    {:ok, result}
  end

  # Find any arguments that have been marked as invalid due to a missing
  # associated schema node.
  @spec handle_node(Blueprint.node_t) :: Blueprint.node_t
  defp handle_node(%Blueprint.Input.Argument{schema_node: nil} = node) do
    node
    |> flag_invalid(:no_schema_node)
    |> put_error(error(node))
  end
  defp handle_node(node) do
    node
  end

  # Generate the error for the node
  @spec error(Blueprint.node_t) :: Phase.Error.t
  defp error(node) do
    Phase.Error.new(
      __MODULE__,
      "Unknown argument.",
      node.source_location
    )
  end

end
