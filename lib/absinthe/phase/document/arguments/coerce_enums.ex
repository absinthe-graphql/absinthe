defmodule Absinthe.Phase.Document.Arguments.CoerceEnums do
  @moduledoc false

  # Coerce variable string inputs to enums when appropriate.
  #
  # A literal enum like `foo(arg: ENUM)` is parsed as an `Input.Enum` struct.
  #
  # However when a variable is used `foo(arg: $enumVar)` the variable input ends up
  # being an `Input.String` because the variable handler does not yet know the
  # schema type. This phase coerces string to enum inputs when the schema type
  # is an Enum.

  use Absinthe.Phase
  alias Absinthe.{Blueprint, Type}
  alias Absinthe.Blueprint.Input

  @spec run(Blueprint.t(), Keyword.t()) :: {:ok, Blueprint.t()}
  def run(input, _options \\ []) do
    node = Blueprint.prewalk(input, &coerce_node/1)
    {:ok, node}
  end

  defp coerce_node(%Input.Value{raw: %{content: %Input.Variable{}}} = node) do
    node =
      Blueprint.prewalk(node, fn
        %Input.String{} = input ->
          case Type.unwrap(input.schema_node) do
            %Type.Enum{} ->
              Map.put(input, :__struct__, Input.Enum)

            _ ->
              input
          end

        node ->
          node
      end)

    {:halt, node}
  end

  defp coerce_node(node), do: node
end
