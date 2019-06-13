defmodule Absinthe.Phase.Schema.Arguments.Normalize do
  @moduledoc false

  # Populate all arguments in the document with their provided values:
  #
  # - If a literal value is provided for an argument, set the `Argument.t`'s
  #   `normalized_value` field to that value.
  #
  # Note that no validation occurs in this phase.

  use Absinthe.Phase
  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Input

  @spec run(Blueprint.t(), Keyword.t()) :: {:ok, Blueprint.t()}
  def run(input, _options \\ []) do
    node = Blueprint.prewalk(input, &handle_node/1)
    {:ok, node}
  end

  # Set provided value from the raw value
  defp handle_node(%Input.RawValue{} = node) do
    %Input.Value{
      normalized: node.content,
      raw: node
    }
  end

  defp handle_node(node) do
    node
  end
end
