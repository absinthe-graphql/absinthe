defmodule Absinthe.Schema.Notation.FieldImporter do
  def normalize_definitions(definitions) do
    definitions_map = definitions |> build_def_map

    definitions = Enum.map(definitions, &normalize(&1, definitions_map))
    {definitions, []}
  end

  defp normalize(obj, map) do
    case obj.attrs[:field_imports] do
      []->
        obj
      nil ->
        obj
      imports ->
        %{obj | attrs: Keyword.update!(obj.attrs, :fields, &import_fields(imports, &1, map))}
    end
  end

  # Walk through the items we want to import fields from, get their fields,
  # and walk to any objects THEY import to get their fields, etc.
  defp import_fields(nil, existing_fields, _), do: existing_fields
  defp import_fields([], existing_fields, _), do: existing_fields
  defp import_fields([{obj_ref, _opts} | rest], existing_fields, map) do
    referenced_obj = Map.fetch!(map, obj_ref)
    imported_fields = import_fields(referenced_obj.attrs[:field_imports], referenced_obj.attrs[:fields], map)

    import_fields(rest, Keyword.merge(fields, imported_fields), map)
  end

  # builds a map of identifiers to definitions
  # this is non trivial because the definition contents are largely AST
  defp build_def_map(definitions) do
    definitions
    |> Enum.filter(&(&1.attrs[:__reference__]))
    |> Map.new(fn definition ->
      {_, _, ref_attrs} = definition.attrs[:__reference__]
      {Keyword.fetch!(ref_attrs, :identifier), definition}
    end)
  end
end
