defmodule Absinthe.Schema.Notation.FieldImporter do
  def normalize_definitions(definitions) do
    definitions_map = definitions |> build_def_map
    errors = []
    acc = []

    normalize(definitions, definitions_map, errors, [])
  end

  def normalize([], map, errors, acc) do
    {:lists.reverse(acc), errors}
  end
  def normalize([definition | rest], map, errors, acc) do
    case do_normalize(definition, map) do
      {:ok, definition} ->
        normalize(rest, map, errors, [definition | acc])
      {:error, error} ->
        normalize(rest, map, [error | errors], acc)
    end
  end

  defp do_normalize(obj, map) do
    case obj.attrs[:field_imports] do
      []->
        {:ok, obj}
      nil ->
        {:ok, obj}
      imports ->
        with {:ok, fields} <- import_fields(imports, map, obj, obj.attrs[:fields]) do
          {:ok, %{obj | attrs: Keyword.update!(obj.attrs, :fields, fn _ -> fields end)}}
        end
    end
  end

  # Walk through the items we want to import fields from, get their fields,
  # and walk to any objects THEY import to get their fields, etc.
  defp import_fields(nil, _map, _parent, fields), do: {:ok, fields}
  defp import_fields([], _map, _parent, fields), do: {:ok, fields}
  defp import_fields([{obj_ref, _opts} | rest], map, parent, existing_fields) do
    with {:ok, %{attrs: attrs} = obj} <- find_obj(obj_ref, map, parent),
    {:ok, fields} <- import_fields(attrs[:field_imports], map, obj, attrs[:fields]) do
      import_fields(rest, map, parent, Keyword.merge(fields, existing_fields))
    end
  end

  defp find_obj(obj_ref, map, parent) do
    with :error <- Map.fetch(map, obj_ref) do
      {:error, error(parent, "Type #{inspect obj_ref} not found in schema")}
    end
  end

  defp error(definition, msg) do
    %{
      location: %{file: definition.file, line: definition.line},
      data: %{artifact: msg, value: definition.identifier}
    }
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
