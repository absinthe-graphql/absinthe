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

  defp process(%Argument{input_value: %{normalized: %Object{} = object}} = node) do
    non_null_field_count =
      object.fields
      |> Enum.map(&get_in(&1.input_value.normalized.__struct__))
      |> Enum.count(&(&1 != Absinthe.Blueprint.Input.Null))

    if (get_in(object.schema_node.__private__[:one_of]) || false) and non_null_field_count > 1 do
      message =
        ~s[The Input Type "#{object.schema_node.name}" has the @oneOf directive. It must have exactly one non-null field. It has #{non_null_field_count}.]

      error = %Error{locations: [node.source_location], message: message, phase: __MODULE__}
      put_error(node, error)
    else
      node
    end
  end

  defp process(node), do: node
end
