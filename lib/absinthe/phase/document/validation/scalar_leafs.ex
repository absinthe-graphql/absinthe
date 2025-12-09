# [sic]
defmodule Absinthe.Phase.Document.Validation.ScalarLeafs do
  @moduledoc false

  # Validates that all leaf nodes are scalars.
  #
  # # Examples:
  # Assume `user` field is an object, and `email` is a scalar.
  #
  # ## DO NOT
  # ```
  # {
  #   user
  # }
  # ```
  #
  # ## DO
  # ```
  # {
  #   user {name email}
  # }
  # ```
  #
  # ## DO NOT
  # ```
  # {
  #   email { fields on scalar }
  # }
  # ```
  #
  # ## DO
  # ```
  # {
  #   email
  # }
  # ```

  alias Absinthe.{Blueprint, Phase, Phase.Document.Validation.Utils, Type}

  use Absinthe.Phase

  @doc """
  Run the validation.
  """
  @spec run(Blueprint.t(), Keyword.t()) :: Phase.result_t()
  def run(input, options \\ []) do
    result = Blueprint.prewalk(input, &handle_node(&1, input.schema, options))
    {:ok, result}
  end

  defp handle_node(%{schema_node: nil} = node, _schema, _options), do: {:halt, node}

  defp handle_node(%Blueprint.Document.Field{schema_node: schema_node} = node, schema, options) do
    type = Type.expand(schema_node.type, schema)
    process(node, Type.unwrap(type), type, options)
  end

  defp handle_node(node, _, _options) do
    node
  end

  @has_subfields [
    Type.Object,
    Type.Union,
    Type.Interface
  ]

  defp process(%{selections: []} = node, %unwrapped{}, type, options)
       when unwrapped in @has_subfields do
    bad_node(node, type, :missing_subfields, options)
  end

  defp process(%{selections: s} = node, %unwrapped{}, type, options)
       when s != [] and unwrapped not in @has_subfields do
    bad_node(node, type, :bad_subfields, options)
  end

  defp process(node, _, _, _options) do
    node
  end

  defp bad_node(node, type, :bad_subfields = flag, _options) do
    node
    |> flag_invalid(flag)
    |> put_error(error(node, no_subselection_allowed_message(node.name, Type.name(type))))
  end

  defp bad_node(node, type, :missing_subfields = flag, options) do
    node
    |> flag_invalid(flag)
    |> put_error(error(node, required_subselection_message(node.name, Type.name(type), options)))
  end

  # Generate the error
  @spec error(Blueprint.Document.Field.t(), String.t()) :: Phase.Error.t()
  defp error(node, message) do
    %Phase.Error{
      phase: __MODULE__,
      message: message,
      locations: [node.source_location]
    }
  end

  @doc """
  Generate the error message for an extraneous field subselection.
  """
  @spec no_subselection_allowed_message(String.t(), String.t()) :: String.t()
  def no_subselection_allowed_message(field_name, type_name) do
    ~s(Field "#{field_name}" must not have a selection since type "#{type_name}" has no subfields.)
  end

  @doc """
  Generate the error message for a missing field subselection.
  """
  @spec required_subselection_message(String.t(), String.t(), Absinthe.run_opts()) :: String.t()
  def required_subselection_message(field_name, type_name, options) do
    suggestions = ["#{field_name} { ... }"]

    ~s(Field "#{field_name}" of type "#{type_name}" must have a selection of subfields.) <>
      Utils.MessageSuggestions.suggest_message(suggestions, options)
  end
end
