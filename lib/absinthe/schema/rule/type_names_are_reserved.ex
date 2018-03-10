defmodule Absinthe.Schema.Rule.TypeNamesAreReserved do
  use Absinthe.Schema.Rule

  alias Absinthe.Schema

  @moduledoc false

  @description """
  Type system artifacts must not begin with two leading underscores.

  > GraphQL type system authors must not define any types, fields, arguments,
  > or any other type system artifact with two leading underscores.

  Reference: https://github.com/facebook/graphql/blob/master/spec/Section%204%20--%20Introspection.md#naming-conventions

  """

  def explanation(%{data: %{artifact: artifact, value: value}}) do
    artifact_name = String.capitalize(artifact)

    """
    #{artifact_name} #{inspect(value)} starts with two leading underscores.

    #{@description}
    """
  end

  def check(schema) do
    Enum.flat_map(Schema.types(schema), &check_type(schema, &1)) ++
      Enum.flat_map(Schema.directives(schema), &check_directive(schema, &1))
  end

  defp check_type(schema, %{fields: fields} = type) do
    check_named(schema, type, "type", type) ++
      Enum.flat_map(fields |> Map.values(), &check_field(schema, type, &1))
  end

  defp check_type(schema, type) do
    check_named(schema, type, "type", type)
  end

  defp check_field(schema, type, field) do
    check_named(schema, type, "field", field) ++
      Enum.flat_map(field.args |> Map.values(), &check_arg(schema, type, &1))
  end

  defp check_directive(schema, directive) do
    check_named(schema, directive, "directive", directive) ++
      Enum.flat_map(directive.args |> Map.values(), &check_arg(schema, directive, &1))
  end

  defp check_arg(schema, type, arg) do
    check_named(schema, type, "argument", arg)
  end

  defp check_named(_schema, type, kind, %{name: "__" <> _} = entity) do
    if Absinthe.Type.built_in?(type) do
      []
    else
      [report(entity.__reference__.location, %{artifact: "#{kind} name", value: entity.name})]
    end
  end

  defp check_named(_, _, _, _) do
    []
  end
end
