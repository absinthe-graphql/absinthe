defmodule Absinthe.Schema.Verification do

  alias Absinthe.Traversal
  alias Absinthe.Schema
  alias Absinthe.Type

  @spec setup(Schema.t) :: Schema.t
  def setup(schema) do
    errors = Traversal.reduce(schema, schema, [], &collect_errors/3)
    %{schema | errors: schema.errors ++ errors}
  end

  # Don't allow anything named with a __ prefix
  @spec collect_errors(Traversal.Node.t, Traversal.t, [binary]) :: Traversal.instruction_t
  defp collect_errors(%{__struct__: definition_type, name: "__" <> name}, traversal, acc) do
    definition_name = definition_type |> Module.split |> List.last
    errs = [format_error(:double_underscore, %{definition: definition_name, name: name}) | acc]
    {:ok, errs, traversal}
  end
  # No-op
  defp collect_errors(_node, traversal, acc) do
    {:ok, acc, traversal}
  end

  defp format_error(:double_underscore, %{definition: definition, name: name}) do
    "#{definition} `__#{name}': Must not define any types, fields, arguments, or any other type system artifact with two leading underscores."
  end

end
