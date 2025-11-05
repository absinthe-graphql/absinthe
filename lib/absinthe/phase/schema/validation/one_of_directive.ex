defmodule Absinthe.Phase.Schema.Validation.OneOfDirective do
  @moduledoc false

  # Schema validation phase that ensures that uses of the `@oneOf` directive comply with the spec

  use Absinthe.Phase

  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Schema.InputObjectTypeDefinition
  alias Absinthe.Blueprint.TypeReference.NonNull

  def run(blueprint, _options \\ []) do
    {:ok, Blueprint.prewalk(blueprint, &process/1)}
  end

  defp process(%InputObjectTypeDefinition{directives: [_ | _] = directives} = node) do
    one_of? = Enum.any?(directives, &(&1.name == "one_of"))

    cond do
      one_of? and length(node.fields) == 1 ->
        add_error(node, """
        The oneOf directive is only valid on input types with more then one field.
        The input type "#{node.name}" only defines one field.
        """)

      one_of? and Enum.any?(node.fields, &match?(%NonNull{}, &1.type)) ->
        add_error(node, """
        The oneOf directive is only valid on input types with all nullable fields.
        The input type "#{node.name}" has one or more nullable fields.
        """)

      true ->
        node
    end
  end

  defp process(node), do: node

  defp add_error(node, message) do
    error = %Absinthe.Phase.Error{
      locations: [node.__reference__.location],
      message: message,
      phase: __MODULE__
    }

    put_error(node, error)
  end
end
