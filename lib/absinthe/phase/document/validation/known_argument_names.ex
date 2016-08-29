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

  @spec run(Blueprint.t) :: Phase.result_t
  def run(input) do
    result = Blueprint.prewalk(input, &handle_node/1)
    {:ok, result}
  end

  defp handle_node(%Blueprint.Input.Argument{schema_node: nil} = node) do
    flags = [:invalid, :no_schema_node]
    %{
      node |
      flags: flags ++ node.flags,
      errors: [error(node) | node.errors]
    }
  end
  defp handle_node(node) do
    node
  end

  defp error(node) do
    Phase.Error.new(
      __MODULE__,
      "Unknown argument.",
      node.source_location
    )
  end

end
