defmodule Absinthe.Resolution.Projector do
  @moduledoc false

  alias Absinthe.{Blueprint, Type}

  @doc """
  Project one layer down from where we are right now.

  Projection amounts to collecting the next set of fields to operate on, based on
  the current field. This is a non trivial operation because you have to handle
  the various type conditions that come along with fragments / inline fragments,
  field merging, and other wonderful stuff like that.
  """
  def project(selections, %{identifier: parent_ident} = parent_type, path, cache, exec) do
    path =
      for %{parent_type: %{identifier: i}, name: name, alias: alias} <- path do
        {i, alias || name}
      end

    key = [parent_ident | path]

    case Map.fetch(cache, key) do
      {:ok, fields} ->
        {fields, cache}

      _ ->
        fields =
          selections
          |> collect(parent_type, exec)
          |> rectify_order

        {fields, Map.put(cache, key, fields)}
    end
  end

  defp response_key(%{alias: nil, name: name}), do: name
  defp response_key(%{alias: alias}), do: alias
  defp response_key(%{name: name}), do: name

  defp collect(selections, parent_type, %{fragments: fragments, schema: schema}) do
    {acc, _index} = do_collect(selections, fragments, parent_type, schema, 0, %{})
    acc
  end

  defp do_collect([], _, _, _, index, acc), do: {acc, index}

  defp do_collect([selection | selections], fragments, parent_type, schema, index, acc) do
    case selection do
      %{flags: %{skip: _}} ->
        do_collect(selections, fragments, parent_type, schema, index, acc)

      # Skip nodes that have been explicitly marked for skipping in streaming resolution
      # Note: :defer and :stream flags alone do NOT cause skipping in standard resolution
      # Only :__skip_initial__ flag (set by streaming_resolution) causes skipping
      %{flags: %{__skip_initial__: true}} ->
        do_collect(selections, fragments, parent_type, schema, index, acc)

      %Blueprint.Document.Field{} = field ->
        field = update_schema_node(field, parent_type)
        key = response_key(field)

        acc =
          Map.update(acc, key, {index, [field]}, fn {existing_index, fields} ->
            {existing_index, [field | fields]}
          end)

        do_collect(selections, fragments, parent_type, schema, index + 1, acc)

      %Blueprint.Document.Fragment.Inline{
        type_condition: %{schema_node: condition},
        selections: inner_selections
      } ->
        {acc, index} =
          conditionally_collect(
            condition,
            inner_selections,
            fragments,
            parent_type,
            schema,
            index,
            acc
          )

        do_collect(selections, fragments, parent_type, schema, index, acc)

      %Blueprint.Document.Fragment.Spread{name: name} ->
        %{type_condition: condition, selections: inner_selections} = Map.fetch!(fragments, name)

        {acc, index} =
          conditionally_collect(
            condition,
            inner_selections,
            fragments,
            parent_type,
            schema,
            index,
            acc
          )

        do_collect(selections, fragments, parent_type, schema, index, acc)
    end
  end

  defp rectify_order(grouped_fields) do
    grouped_fields
    |> Enum.sort(fn {_, {i1, _}}, {_, {i2, _}} ->
      i1 <= i2
    end)
    |> Enum.map(fn
      {_k, {_index, [field]}} ->
        field

      {_k, {_index, [%{selections: selections} = field | rest]}} ->
        %{field | selections: flatten(rest, selections)}
    end)
  end

  defp flatten([], acc), do: acc

  defp flatten([%{selections: selections} | fields], acc) do
    flatten(fields, selections ++ acc)
  end

  defp conditionally_collect(condition, selections, fragments, parent_type, schema, index, acc) do
    condition
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

  defp update_schema_node(%{schema_node: %{identifier: identifier}} = field, %{
         fields: concrete_fields
       }) do
    %{field | schema_node: :maps.get(identifier, concrete_fields)}
  end

  defp normalize_condition(%{schema_node: condition}, schema) do
    normalize_condition(condition, schema)
  end

  defp normalize_condition(condition, schema) do
    case Type.unwrap(condition) do
      %{} = condition -> condition
      value -> Absinthe.Schema.lookup_type(schema, value)
    end
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
