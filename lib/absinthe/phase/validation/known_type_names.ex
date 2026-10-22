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

  @doc """
  Run the validation.
  """
  @spec run(Blueprint.t(), Keyword.t()) :: Phase.result_t()
  def run(input, options \\ []) do
    result = Blueprint.postwalk(input, &handle_node(&1, input.schema, options))
    {:ok, result}
  end

  defp handle_node(%{type_condition: type, schema_node: nil} = node, _, options)
       when not is_nil(type) do
    name = Blueprint.TypeReference.unwrap(type).name
    error = error(node, name, options)

    node
    |> flag_invalid(:bad_type_name)
    |> put_error(error)
  end

  defp handle_node(%Blueprint.Document.VariableDefinition{} = node, schema, options) do
    name = Blueprint.TypeReference.unwrap(node.type).name
    inner_schema_type = schema.__absinthe_lookup__(name)

    if inner_schema_type do
      node
    else
      suggestions = suggested_type_names(schema, name)
      error = error(node, name, suggestions, options)

      node
      |> flag_invalid(:bad_type_name)
      |> put_error(error)
    end
  end

  defp handle_node(node, _, _options) do
    node
  end

  defp suggested_type_names(schema, name) do
    schema
    |> Absinthe.Schema.referenced_types()
    |> Enum.map(& &1.name)
    |> Absinthe.Utils.Suggestion.sort_list(name)
  end

  @spec error(Blueprint.node_t(), String.t(), Absinthe.run_opts()) :: Phase.Error.t()
  defp error(node, name, suggestions \\ [], options) do
    %Phase.Error{
      phase: __MODULE__,
      message: message(name, suggestions, options),
      locations: [node.source_location]
    }
  end

  defp message(name, [], _options) do
    ~s(Unknown type "#{name}".)
  end

  defp message(name, suggestions, options) do
    ~s(Unknown type "#{name}".) <> Utils.MessageSuggestions.suggest_message(suggestions, options)
  end
end
