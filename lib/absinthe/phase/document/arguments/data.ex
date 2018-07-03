defmodule Absinthe.Phase.Document.Arguments.Data do
  @moduledoc false

  # Populate all arguments in the document with their provided data values:
  #
  # - If valid data is available for an argument, set the `Argument.t`'s
  #   `data_value` field to that value.
  # - If no valid data is available for an argument, set the `Argument.t`'s
  #   `data_value` to `nil`.
  # - When determining the value of the argument, mark any invalid nodes
  #   in the `Argument.t`'s `normalized_value` tree with `:invalid` and a
  #   reason.
  # - If non-null arguments are not provided (eg, a `Argument.t` is missing
  #   from `normalized_value`), add a stub `Argument.t` and flag it as
  #   `:invalid` and `:missing`.
  # - If non-null input fields are not provided (eg, an `Input.Field.t` is
  #   missing from `normalized_value`), add a stub `Input.Field.t` and flag it as
  #   `:invalid` and `:missing`.
  #
  # Note that the limited validation that occurs in this phase is limited to
  # setting the `data_value` to `nil`, adding flags to the `normalized_value`,
  # and building stub fields/arguments when missing values are required. Actual
  # addition of errors is handled by validation phases.

  alias Absinthe.Blueprint.Input
  alias Absinthe.{Blueprint}
  use Absinthe.Phase

  def run(input, _options \\ []) do
    # By using a postwalk we can worry about leaf nodes first (scalars, enums),
    # and then for list and objects merely grab the data values.
    result = Blueprint.postwalk(input, &handle_node/1)
    {:ok, result}
  end

  def handle_node(%Blueprint.Document.Field{arguments: []} = node) do
    node
  end

  def handle_node(%Blueprint.Document.Field{arguments: args} = node) do
    %{node | argument_data: Input.Argument.value_map(args)}
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
        {field.schema_node.__reference__.identifier, field.input_value.data}
      end

    %{node | data: data}
  end

  def handle_node(node) do
    node
  end

  defp include_field?(%{input_value: %{normalized: %Input.Null{}}}), do: true
  defp include_field?(%{input_value: %{data: nil}}), do: false
  defp include_field?(_), do: true
end
