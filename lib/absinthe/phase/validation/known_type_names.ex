defmodule Absinthe.Phase.Validation.KnownTypeNames do
  @moduledoc false

  # Ensure type names actually exist in the schema.
  #
  # Type names show up for example in fragments:
  #
  # ```
  # fragment foo on Foo {
  #   name
  # }
  # ```

  alias Absinthe.{Blueprint, Phase}

  use Absinthe.Phase
  use Absinthe.Phase.Validation

  @doc """
  Run the validation.
  """
  @spec run(Blueprint.t(), Keyword.t()) :: Phase.result_t()
  def run(input, _options \\ []) do
    result = Blueprint.postwalk(input, &handle_node(&1, input.schema))
    {:ok, result}
  end

  defp handle_node(%{type_condition: type, schema_node: nil} = node, _) when not is_nil(type) do
    name = Blueprint.TypeReference.unwrap(type).name

    node
    |> flag_invalid(:bad_type_name)
    |> put_error(error(node, name))
  end

  defp handle_node(%Blueprint.Document.VariableDefinition{schema_node: nil} = node, schema) do
    name = Blueprint.TypeReference.unwrap(node.type).name
    inner_schema_type = schema.__absinthe_lookup__(name)

    if inner_schema_type do
      node
    else
      node
      |> flag_invalid(:bad_type_name)
      |> put_error(error(node, name))
    end
  end

  defp handle_node(node, _) do
    node
  end

  @spec error(Blueprint.node_t(), String.t()) :: Phase.Error.t()
  defp error(node, name) do
    %Phase.Error{
      phase: __MODULE__,
      message: ~s(Unknown type "#{name}".),
      locations: [node.source_location]
    }
  end
end
