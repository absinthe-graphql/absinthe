defmodule Absinthe.Phase.Document.Validation.UniqueInputFieldNames do
  @moduledoc """
  Validates document to ensure that all input fields have unique names.
  """

  alias Absinthe.{Blueprint, Phase}

  use Absinthe.Phase
  use Absinthe.Phase.Document.Validation

  @spec run(Blueprint.t) :: Phase.result_t
  def run(input) do
    result = Blueprint.prewalk(input, &handle_node/1)
    {:ok, result}
  end

  defp handle_node(%Blueprint.Input.Object{} = node) do
    fields = Enum.map(node.fields, &(process(&1, node.fields)))
    %{node | fields: fields}
    |> inherit_invalid(fields, :duplicate_fields)
  end
  defp handle_node(node) do
    node
  end

  defp process(field, fields) do
    do_process(field, Enum.filter(fields, &(&1.name == field.name)))
  end

  defp do_process(field, [_single]) do
    field
  end
  defp do_process(field, _multiple) do
    %{
      field |
      flags: [:invalid, :duplicate_name] ++ field.flags,
      errors: [error(field) | field.errors]
    }
  end

  defp error(node) do
    Phase.Error.new(
      __MODULE__,
      "Duplicate input field name.",
      node.source_location
    )
  end

end
