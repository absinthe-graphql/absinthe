defmodule Absinthe.Phase.Document.Validation.OneOfDirective do
  @moduledoc false

  # Document validation phase that ensures that only one value is provided for input types
  # that have the oneOf directive set

  use Absinthe.Phase

  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Input.Object
  alias Absinthe.Phase.Error
  alias Absinthe.Type

  def run(blueprint, _options \\ []) do
    {:ok, Blueprint.prewalk(blueprint, &process/1)}
  end

  defp process(%Object{schema_node: %Type.InputObject{__private__: private} = schema_node} = node) do
    if Keyword.has_key?(private, :one_of) and field_count(node.fields) != 1 do
      message =
        ~s[The Input Type "#{schema_node.name}" has the @oneOf directive. It must have exactly one non-null field.]

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
