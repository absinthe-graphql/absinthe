defmodule Absinthe.Phase.Document.Validation.KnownArgumentNames do
  @moduledoc false

  # Validates document to ensure that all arguments are in the schema.
  #
  # Note: while graphql-js doesn't add errors to unknown arguments that
  # are provided to unknown fields, Absinthe does -- but when the errors
  # are harvested from the Blueprint tree, only the first layer of unknown
  # errors (eg, the field) should be presented to the user.

  alias Absinthe.{Blueprint, Phase, Schema, Type}

  use Absinthe.Phase

  @doc """
  Run the validation.
  """
  @spec run(Blueprint.t(), Keyword.t()) :: Phase.result_t()
  def run(input, _options \\ []) do
    result = Blueprint.prewalk(input, &handle_node(&1, input.schema))
    {:ok, result}
  end

  @spec handle_node(Blueprint.node_t(), Schema.t()) :: Blueprint.node_t()
  defp handle_node(%{schema_node: nil} = node, _schema) do
    node
  end

  defp handle_node(%{selections: _, schema_node: schema_node} = node, schema) do
    selections =
      Enum.map(node.selections, fn
        %{arguments: arguments} = field ->
          arguments =
            Enum.map(arguments, fn
              %{schema_node: nil} = arg ->
                arg
                |> flag_invalid(:no_schema_node)
                |> put_error(field_error(arg, field, type_name(schema_node, schema)))

              other ->
                other
            end)

          %{field | arguments: arguments}

        other ->
          other
      end)

    %{node | selections: selections}
  end

  defp handle_node(%Blueprint.Directive{} = node, _) do
    arguments =
      Enum.map(node.arguments, fn
        %{schema_node: nil} = arg ->
          arg
          |> flag_invalid(:no_schema_node)
          |> put_error(directive_error(arg, node))

        other ->
          other
      end)

    %{node | arguments: arguments}
  end

  defp handle_node(node, _) do
    node
  end

  @spec type_name(Type.t(), Schema.t()) :: String.t()
  defp type_name(%Type.Field{} = node, schema) do
    node.type
    |> Type.unwrap()
    |> schema.__absinthe_lookup__()
    |> Map.fetch!(:name)
  end

  defp type_name(node, _) do
    node.name
  end

  # Generate the error for a directive argument
  @spec directive_error(Blueprint.node_t(), Blueprint.node_t()) :: Phase.Error.t()
  defp directive_error(argument_node, directive_node) do
    %Phase.Error{
      phase: __MODULE__,
      message: directive_error_message(argument_node.name, directive_node.name),
      locations: [argument_node.source_location]
    }
  end

  # Generate the error for a field argument
  @spec field_error(Blueprint.node_t(), Blueprint.node_t(), String.t()) :: Phase.Error.t()
  defp field_error(argument_node, field_node, type_name) do
    %Phase.Error{
      phase: __MODULE__,
      message: field_error_message(argument_node.name, field_node.name, type_name),
      locations: [argument_node.source_location]
    }
  end

  @doc """
  Generate an error for a directive argument
  """
  @spec directive_error_message(String.t(), String.t()) :: String.t()
  def directive_error_message(argument_name, directive_name) do
    ~s(Unknown argument "#{argument_name}" on directive "@#{directive_name}".)
  end

  @doc """
  Generate an error for a field argument
  """
  @spec field_error_message(String.t(), String.t(), String.t()) :: String.t()
  def field_error_message(argument_name, field_name, type_name) do
    ~s(Unknown argument "#{argument_name}" on field "#{field_name}" of type "#{type_name}".)
  end
end
