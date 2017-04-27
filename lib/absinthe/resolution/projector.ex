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

  defp collect(selections, %{fragments: fragments, parent_type: parent_type, schema: schema}) do
    {acc, _index} = do_collect(selections, fragments, parent_type, schema, 0, %{})
    acc
  end

  defp do_collect([], _, _, _, index, acc), do: {acc, index}
  defp do_collect([selection | selections], fragments, parent_type, schema, index, acc) do
    case selection do
      %{flags: %{skip: _}} ->
        do_collect(selections, fragments, parent_type, schema, index, acc)

      %Blueprint.Document.Field{} = field ->
        field = update_schema_node(field, parent_type)
        key = response_key(field)

        acc = Map.update(acc, key, {index, [field]}, fn {existing_index, fields} ->
          {existing_index, [field | fields]}
        end)

        do_collect(selections, fragments, parent_type, schema, index + 1, acc)

      %Blueprint.Document.Fragment.Inline{type_condition: %{schema_node: condition}, selections: inner_selections} ->
        {acc, index} = conditionally_collect(condition, inner_selections, fragments, parent_type, schema, index, acc)

        do_collect(selections, fragments, parent_type, schema, index, acc)

      %Blueprint.Document.Fragment.Spread{name: name} ->
        %{type_condition: condition, selections: inner_selections} = Map.fetch!(fragments, name)

        {acc, index} = conditionally_collect(condition, inner_selections, fragments, parent_type, schema, index, acc)

        do_collect(selections, fragments, parent_type, schema, index, acc)
    end
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

  defp conditionally_collect(condition, selections, fragments, parent_type, schema, index, acc) do
    condition
    |> Type.unwrap
    |> normalize_condition(schema)
    |> passes_type_condition?(parent_type)
    |> case do
      true -> do_collect(selections, fragments, parent_type, schema, index, acc)
      false -> {acc, index}
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
