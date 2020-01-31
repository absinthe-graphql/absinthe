defmodule Absinthe.Phase.Schema.Arguments.Data do
  @moduledoc false

  # Populate all arguments in the SDL with their provided data values.
  #
  # See Absinthe.Phase.Document.Arguments.Data for a more expansive
  # explanation; this phase limits itself to arguments and values.

  alias Absinthe.Blueprint.Input
  alias Absinthe.{Blueprint}
  use Absinthe.Phase

  def run(input, _options \\ []) do
    # By using a postwalk we can worry about leaf nodes first (scalars, enums),
    # and then for list and objects merely grab the data values.
    result = Blueprint.postwalk(input, &handle_node/1)
    {:ok, result}
  end

  def handle_node(%Input.Argument{input_value: input} = node) do
    %{node | value: input.data}
  end

  def handle_node(%Input.Value{normalized: %Input.List{items: items}} = node) do
    data_list = for %{data: data} = item <- items, Input.Value.valid?(item), do: data
    %{node | data: data_list}
  end

  def handle_node(%Input.Value{normalized: %Input.Object{fields: fields}} = node) do
    data =
      for field <- fields, include_field?(field), into: %{} do
        {field.schema_node.identifier, field.input_value.data}
      end

    %{node | data: data}
  end

  def handle_node(node) do
    node
  end

  defp include_field?(%{input_value: %{normalized: %Input.Null{}}}), do: true
  defp include_field?(%{input_value: %{data: nil}}), do: false
  defp include_field?(%{schema_node: nil}), do: false
  defp include_field?(_), do: true
end
