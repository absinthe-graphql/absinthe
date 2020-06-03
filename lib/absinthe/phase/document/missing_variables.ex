defmodule Absinthe.Phase.Document.MissingVariables do
  @moduledoc false

  # Fills out missing arguments and input object fields.
  #
  # Filling out means inserting a stubbed `Input.Argument` or `Input.Field` struct.
  #
  # Only those arguments which are non null and / or have a default value are filled
  # out.
  #
  # If an argument or input object field is non null and missing, it is marked invalid

  use Absinthe.Phase
  alias Absinthe.{Blueprint, Type}

  @spec run(Blueprint.t(), Keyword.t()) :: {:ok, Blueprint.t()}
  def run(input, _options \\ []) do
    node = Blueprint.prewalk(input, &handle_node/1)
    {:ok, node}
  end

  defp handle_node(
         %Blueprint.Input.Argument{schema_node: schema_node, input_value: %{normalized: nil}} =
           node
       ) do
    handle_defaults(node, schema_node)
  end

  defp handle_node(
         %Blueprint.Input.Field{schema_node: schema_node, input_value: %{normalized: nil}} = node
       ) do
    handle_defaults(node, schema_node)
  end

  defp handle_node(node), do: node

  defp handle_defaults(node, schema_node) do
    case schema_node do
      %{default_value: val} when not is_nil(val) ->
        fill_default(node, val)

      %{deprecation: %{}} ->
        node

      %{type: %Type.NonNull{}} ->
        node |> flag_invalid(:missing)

      _ ->
        node
    end
  end

  defp fill_default(%{input_value: input} = node, val) do
    input = %{input | data: val, normalized: %Blueprint.Input.Generated{by: __MODULE__}}
    %{node | input_value: input}
  end
end
