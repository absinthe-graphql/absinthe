defmodule Absinthe.Schema.Problems.ReservedNames do

  def from(schema) do
    schema.__absinthe_types__
    |> Enum.flat_map(fn
      {ident, name} ->
        type = schema.__absinthe_type__(ident)
        [
          reserved_types(schema, {ident, name}, type),
          reserved_fields(schema, type)
        ]
    end)
    |> List.flatten
  end

  def reserved_types(schema, {ident, name}, type) do
    Enum.flat_map([ident, name], fn
      "__" <> _ ->
        [%{name: :res_type_name, location: type.reference.location, data: name}]
      id when is_atom(id) ->
        if match?("__" <> _, Atom.to_string(id)) do
          [%{name: :res_type_ident, location: type.reference.location, data: ident}]
        else
          []
        end
      _ ->
        []
    end)
  end

  def reserved_fields(schema, %{fields: fields} = type) do
    fields
    |> Enum.flat_map(fn
      {_, %{name: "__" <> _ = name}} ->
        [%{name: :res_field_name, location: type.reference.location, data: name}]
      field ->
        []
    end)
  end
  def reserved_fields(_, _) do
    []
  end

end
