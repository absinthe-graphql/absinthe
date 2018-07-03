defmodule Absinthe.Phase.Document.Validation.UniqueInputFieldNames do
  @moduledoc false

  # Validates document to ensure that all input fields have unique names.

  alias Absinthe.{Blueprint, Phase}

  use Absinthe.Phase
  use Absinthe.Phase.Validation

  @doc """
  Run the validation.
  """
  @spec run(Blueprint.t(), Keyword.t()) :: Phase.result_t()
  def run(input, _options \\ []) do
    result = Blueprint.prewalk(input, &handle_node/1)
    {:ok, result}
  end

  # Find input objects
  @spec handle_node(Blueprint.node_t()) :: Blueprint.node_t()
  defp handle_node(%{normalized: %Blueprint.Input.Object{} = node} = parent) do
    fields = Enum.map(node.fields, &process(&1, node.fields))
    node = %{node | fields: fields}
    %{parent | normalized: node}
  end

  defp handle_node(node) do
    node
  end

  # Check an input field, finding any duplicates
  @spec process(Blueprint.Input.Field.t(), [Blueprint.Input.Field.t()]) ::
          Blueprint.Input.Field.t()
  defp process(field, fields) do
    check_duplicates(field, Enum.filter(fields, &(&1.name == field.name)))
  end

  # Add flags and errors if necessary for each input field
  @spec check_duplicates(Blueprint.Input.Field.t(), [Blueprint.Input.Field.t()]) ::
          Blueprint.Input.Field.t()
  defp check_duplicates(field, [_single]) do
    field
  end

  defp check_duplicates(field, _multiple) do
    field
    |> flag_invalid(:duplicate_name)
    |> put_error(error(field))
  end

  # Generate an error for an input field
  @spec error(Blueprint.Input.Field.t()) :: Phase.Error.t()
  defp error(node) do
    %Phase.Error{
      phase: __MODULE__,
      message: error_message(),
      locations: [node.source_location]
    }
  end

  @doc """
  Generate the error message.
  """
  @spec error_message :: String.t()
  def error_message do
    "Duplicate input field name."
  end
end
