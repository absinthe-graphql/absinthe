defmodule Absinthe.Phase.Document.Arguments.Data do
  @moduledoc """
  Populate all arguments in the document with their provided data values:

  - If valid data is available for an argument, set the `Argument.t`'s
    `data_value` field to that value.
  - If no valid data is available for an argument, set the `Argument.t`'s
    `data_value` to `nil`.
  - When determining the value of the argument, mark any invalid nodes
    in the `Argument.t`'s `normalized_value` tree with `:invalid` and a
    reason.
  - If non-null arguments are not provided (eg, a `Argument.t` is missing
    from `normalized_value`), add a stub `Argument.t` and flag it as
    `:invalid` and `:missing`.
  - If non-null input fields are not provided (eg, an `Input.Field.t` is
    missing from `normalized_value`), add a stub `Input.Field.t` and flag it as
    `:invalid` and `:missing`.

  Note that the limited validation that occurs in this phase is limited to
  setting the `data_value` to `nil`, adding flags to the `normalized_value`,
  and building stub fields/arguments when missing values are required. Actual
  addition of errors is handled by validation phases.
  """

  alias Absinthe.Blueprint.Input
  alias Absinthe.{Blueprint, Type}
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
    data_list = for %{data: data} <- items, data != nil, do: data
    %{node | data: data_list}
  end
  def handle_node(%Input.Value{normalized: %Input.Object{fields: fields}} = node) do
    data =
      fields
      |> Enum.map(&{&1.schema_node.__reference__.identifier, &1.input_value.data})
      |> Enum.filter(fn {_, v} -> v end)
      |> Map.new

    %{node | data: data}
  end
  def handle_node(node) do
    node
  end
  # def handle_node(%Input.Value{schema_node: %Type.Object{}, data: data} = node) do
  #
  # end
  #
  # defp handle_node(%{flags: %{invalid: _}} = node) do
  #   node
  # end
  # # If we weren't supplied a value a later phase needs to handle that
  # # being an issue.
  # defp handle_node(%Input.Value{normalized: nil} = node) do
  #   node
  # end
  # # If we couldn't find the schema node for a normalized value, move on
  # defp handle_node(%Input.Value{normalized: %{schema_node: nil}} = node) do
  #   node
  # end
  # defp handle_node(%Input.Value{normalized: normalized_value} = node) do
  #   case build_value(normalized_value) do
  #     {:ok, data_value} ->
  #       %{node | data: data_value}
  #     {:error, normalized_value} ->
  #       %{node | normalized: normalized_value}
  #   end
  # end
  # defp handle_node(%Input.Argument{input_value: %{data: data}} = node) do
  #   %{node | value: data}
  # end
  # defp handle_node(node), do: node
  #
  #
  # defp build_value(%Input.List{items: items}) do
  #   data = for %{data: data} <- items, do: data
  #   {:ok, data}
  # end
  # defp build_value(%Input.Object{fields: fields}) do
  #   data = Map.new(fields, &{&1.schema_node.__reference__.identifier, &1.input_value.data})
  #   {:ok, data}
  # end
  # defp build_value(%{schema_node: %Type.Scalar{} = schema_node} = node) do
  #   case Type.Scalar.parse(schema_node, node) do
  #     :error ->
  #       {:error, flag_invalid(node, :bad_parse)}
  #     other ->
  #       other
  #   end
  # end
  # defp build_value(%{schema_node: %Type.Enum{} = schema_node} = node) do
  #   case Type.Enum.parse(schema_node, node) do
  #     {:ok, %{value: value}} ->
  #       {:ok, value}
  #     :error ->
  #       {:error, flag_invalid(node, :bad_parse)}
  #   end
  # end

end
