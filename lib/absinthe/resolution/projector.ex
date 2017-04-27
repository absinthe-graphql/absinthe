defmodule Absinthe.Resolution.Projector do

  alias Absinthe.{Blueprint, Type}

  def project(selections, info) do
    # TODO: cache this
    selections
    |> collect(info)
    |> rectify_order
  end

  defp response_key(%{alias: nil, name: name}), do: name
  defp response_key(%{alias: alias}), do: alias
  defp response_key(%{name: name}), do: name

  defp collect(selections, info, index \\ 0)
  defp collect(selections, %{fragments: fragments, parent_type: parent_type} = info, offset) do
    selections
    |> Enum.with_index(offset)
    |> Enum.reduce(%{}, fn
      {%{flags: %{skip: _}}, _index}, acc ->
        acc

      {%Blueprint.Document.Field{} = field, index}, acc ->
        field = update_schema_node(field, parent_type)
        key = response_key(field)

        Map.update(acc, key, {index, [field]}, fn {existing_index, fields} ->
          {existing_index, [field | fields]}
        end)

      {%Blueprint.Document.Fragment.Inline{type_condition: %{schema_node: condition}, selections: selections}, index}, acc ->
        subfields = conditionally_collect(condition, selections, parent_type, info, index)

        merge_subfields(acc, subfields)

      {%Blueprint.Document.Fragment.Spread{name: name}, index}, acc ->
        %{type_condition: condition, selections: selections} = Map.fetch!(fragments, name)

        subfields = conditionally_collect(condition, selections, parent_type, info, index)

        merge_subfields(acc, subfields)
    end)
  end

  defp rectify_order(grouped_fields) do
    grouped_fields
    |> Enum.sort(fn {_, {i1, _}}, {_, {i2, _}} ->
      i1 <= i2
    end)
    |> Enum.map(fn {k, {_index, fields}} ->
      {k, fields}
    end)
  end

  defp merge_subfields(acc, subfields) do
    Map.merge(acc, subfields, fn _k, {index, fields}, {_index, subfields} ->
      {index, subfields ++ fields}
    end)
  end

  defp conditionally_collect(condition, selections, parent_type, %{schema: schema} = info, index) do
    condition
    |> Type.unwrap
    |> normalize_condition(schema)
    |> passes_type_condition?(parent_type)
    |> case do
      true -> collect(selections, info, index)
      false -> %{}
    end
  end

  # necessary when the field in question is on an abstract type.
  defp update_schema_node(%{name: "__" <> _} = field, _) do
    field
  end
  defp update_schema_node(%{schema_node: %{identifier: identifier}} = field, %{fields: concrete_fields}) do
    %{field | schema_node: :maps.get(identifier, concrete_fields)}
  end

  defp normalize_condition(%{schema_node: condition}, schema) do
    normalize_condition(condition, schema)
  end
  defp normalize_condition(%{} = condition, _schema) do
    condition
  end
  defp normalize_condition(condition, schema) do
    Absinthe.Schema.lookup_type(schema, condition)
  end

  defp passes_type_condition?(%Type.Object{name: name}, %Type.Object{name: name}) do
    true
  end
  defp passes_type_condition?(%Type.Interface{} = condition, %Type.Object{} = type) do
    Type.Interface.member?(condition, type)
  end
  defp passes_type_condition?(%Type.Union{} = condition, %Type.Object{} = type) do
    Type.Union.member?(condition, type)
  end
  defp passes_type_condition?(_, _) do
    false
  end
end
