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
  alias Absinthe.Phase.Document.Validation.Utils

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

  defp handle_node(%Blueprint.Document.VariableDefinition{} = node, schema) do
    name = Blueprint.TypeReference.unwrap(node.type).name
    inner_schema_type = schema.__absinthe_lookup__(name)

    if inner_schema_type do
      node
    else
      suggestions = suggested_type_names(schema, name)

      node
      |> flag_invalid(:bad_type_name)
      |> put_error(error(node, name, suggestions))
    end
  end

  defp handle_node(node, _) do
    node
  end

  defp suggested_type_names(schema, name) do
    schema
    |> Absinthe.Schema.referenced_types()
    |> Enum.map(& &1.name)
    |> Absinthe.Utils.Suggestion.sort_list(name)
  end

  @spec error(Blueprint.node_t(), String.t()) :: Phase.Error.t()
  defp error(node, name, suggestions \\ []) do
    %Phase.Error{
      phase: __MODULE__,
      message: message(name, suggestions),
      locations: [node.source_location]
    }
  end

  defp message(name, []) do
    ~s(Unknown type "#{name}".)
  end

  defp message(name, suggestions) do
    ~s(Unknown type "#{name}".) <> Utils.MessageSuggestions.suggest_message(suggestions)
  end
end
