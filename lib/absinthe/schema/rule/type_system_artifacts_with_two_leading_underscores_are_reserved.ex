defmodule Absinthe.Schema.Rule.TypeSystemArtifactsWithTwoLeadingUnderscoresAreReserved do
  use Absinthe.Schema.Rule

  @moduledoc """
  Type system artifacts must not begin with two leading underscores.

  > GraphQL type system authors must not define any types, fields, arguments,
  > or any other type system artifact with two leading underscores.

  Reference: https://github.com/facebook/graphql/blob/master/spec/Section%204%20--%20Introspection.md#naming-conventions

  """

  def explanation(%{data: %{artifact: artifact, value: value}}) do
    """
    #{artifact} #{inspect value} starts with two leading underscores.

    #{@moduledoc}
    """
  end

  def check(schema) do
    from_types = schema.__absinthe_types__
    |> Enum.flat_map(fn
      {ident, name} ->
        type = schema.__absinthe_type__(ident)
        [
          check_types(schema, {ident, name}, type),
          check_fields(schema, type)
        ]
    end)
    from_directives = schema.__absinthe_directives__
    |> Enum.flat_map(fn
      {ident, name} ->
        directive = schema.__absinthe_directive__(ident)
        check_directives(schema, {ident, name}, directive)
    end)
    from_types ++ from_directives |> List.flatten
  end

  defp check_directives(schema, {ident, name}, type) do
    Enum.flat_map([ident, name], fn
      "__" <> _ ->
        [report(type.reference.location, %{artifact: "Directive name", value: name})]
      id when is_atom(id) ->
        if match?("__" <> _, Atom.to_string(id)) do
          [report(type.reference.location, %{artifact: "Directive identifier", value: ident})]
        else
          []
      end
      _ ->
        []
    end) ++ check_args(schema, type, type)
  end

  defp check_types(schema, {ident, name}, type) do
    Enum.flat_map([ident, name], fn
      "__" <> _ ->
        [report(type.reference.location, %{artifact: "Type name", value: name})]
      id when is_atom(id) ->
        if match?("__" <> _, Atom.to_string(id)) do
          [report(type.reference.location, %{artifact: "Absinthe type identifier", value: ident})]
        else
          []
        end
      _ ->
        []
    end)
  end

  defp check_fields(schema, %{fields: fields} = type) do
    fields
    |> Enum.flat_map(fn
      {_, %{name: "__" <> _ = name} = field} ->
        [report(type.reference.location, %{artifact: "Field name", value: name})] ++ check_args(schema, type, field)
      {_, field} ->
        check_args(schema, type, field)
    end)
  end
  defp check_fields(_, _) do
    []
  end

  defp check_args(schema, type, %{args: args}) when is_map(args) do
    args
    |> Enum.flat_map(fn
      {_, %{name: "__" <> _ = name}} ->
        [report(type.reference.location, %{artifact: "Argument name", value: name})]
      field ->
        []
    end)
  end
  defp check_args(_, _, _) do
    []
  end

end
