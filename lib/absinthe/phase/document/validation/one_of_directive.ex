defmodule Absinthe.Phase.Document.Validation.OneOfDirective do
  @moduledoc false

  # Document validation phase that ensures that only one value is provided for input types
  # that have the oneOf directive set

  use Absinthe.Phase

  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Input.Argument
  alias Absinthe.Blueprint.Input.Object
  alias Absinthe.Phase.Error

  def run(blueprint, _options \\ []) do
    {:ok, Blueprint.prewalk(blueprint, &process/1)}
  end

  # Ignore input objects without schema nodes
  defp process(%Argument{input_value: %{normalized: %Object{schema_node: nil}}} = node), do: node

  defp process(%Argument{input_value: %{normalized: %Object{} = object}} = node) do
    if Keyword.has_key?(object.schema_node.__private__, :one_of) and
         field_count(object.fields) > 1 do
      message =
        ~s[The Input Type "#{object.schema_node.name}" has the @oneOf directive. It must have exactly one non-null field.]

      error = %Error{locations: [node.source_location], message: message, phase: __MODULE__}
      put_error(node, error)
    else
      node
    end
  end

  defp process(node), do: node

  defp field_count(fields) do
    fields
    |> Enum.map(fn field ->
      get_in(field, Enum.map(~w[input_value normalized __struct__]a, &Access.key/1))
    end)
    |> Enum.count(&(&1 != Absinthe.Blueprint.Input.Null))
  end
end
