defmodule Absinthe.Schema.Verification do
  @moduledoc false

  alias __MODULE__
  alias Absinthe.Traversal
  alias Absinthe.Schema

  @spec setup(Schema.t()) :: Schema.t()
  def setup(%{errors: []} = schema) do
    errors = Traversal.reduce(schema, schema, schema.errors, &collect_errors/3)

    %{schema | errors: errors}
    |> Verification.Unions.check()
  end

  def setup(schema) do
    schema
  end

  # Don't allow anything named with a __ prefix
  @spec collect_errors(Traversal.Node.t(), Traversal.t(), [binary]) :: Traversal.instruction_t()
  defp collect_errors(%{__struct__: definition_type, name: "__" <> name}, traversal, errs) do
    definition_name = definition_type |> Module.split() |> List.last()
    errs = [format_error(:double_underscore, %{definition: definition_name, name: name}) | errs]
    {:ok, errs, traversal}
  end

  # No-op
  defp collect_errors(_node, traversal, errs) do
    {:ok, errs, traversal}
  end

  defp format_error(:double_underscore, %{definition: definition, name: name}) do
    "#{definition} `__#{name}': Must not define any types, fields, arguments, or any other type system artifact with two leading underscores."
  end
end
