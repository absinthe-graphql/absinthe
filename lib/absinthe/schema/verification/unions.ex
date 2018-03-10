defmodule Absinthe.Schema.Verification.Unions do
  @moduledoc false

  alias Absinthe.Schema
  alias Absinthe.Type

  @spec check(Schema.t()) :: Schema.t()
  def check(schema) do
    schema
    |> unions
    |> Enum.reduce(schema, fn %{types: concrete_types} = union, acc ->
      check_resolvers(union, concrete_types, acc)
    end)
  end

  # Find the union types
  @spec unions(Schema.t()) :: [Type.Union.t()]
  defp unions(schema) do
    schema.types.by_identifier
    |> Map.values()
    |> Enum.filter(fn type -> match?(%Type.Union{}, type) end)
  end

  defp check_resolvers(_union, [], schema) do
    schema
  end

  defp check_resolvers(
         %{resolve_type: nil, __reference__: %{identifier: ident}} = union,
         [concrete_type_ident | rest],
         schema
       ) do
    case schema.types[concrete_type_ident] do
      nil ->
        err = "Could not find concrete type :#{concrete_type_ident} for union type :#{ident}"
        check_resolvers(union, rest, %{schema | errors: [err | schema.errors]})

      %{is_type_of: nil} ->
        err =
          "Union type :#{ident} does not provide a `resolve_type` function and concrete type :#{
            concrete_type_ident
          } does not provide an `is_type_of` function. There is no way to resolve this concrete type during execution."

        check_resolvers(union, rest, %{schema | errors: [err | schema.errors]})

      %{is_type_of: _} ->
        check_resolvers(union, rest, schema)
    end
  end

  defp check_resolvers(%{resolve_type: _}, _concrete_types, schema) do
    schema
  end
end
