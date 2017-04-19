defmodule Absinthe.Resolution.Projector do

  alias Absinthe.{Blueprint, Type}

  def project(selections, info) do
    # TODO: cache this
    selections
    |> do_project(info)
    |> merge(info)
  end

  defp merge(fields, info) do
    # now the fun part
    fields
  end

  defp do_project(selections, %{fragments: fragments, parent_type: parent_type} = info) do
    Enum.flat_map(selections, fn
      %{flags: %{skip: _}} ->
        []

      %Blueprint.Document.Field{} = field ->
        [update_schema_node(field, parent_type)]

      %Blueprint.Document.Fragment.Inline{type_condition: %{schema_node: condition}, selections: selections} ->
        conditionally_project(condition, selections, parent_type, info)

      %Blueprint.Document.Fragment.Spread{name: name} ->
        %{type_condition: condition, selections: selections} = Map.fetch!(fragments, name)
        conditionally_project(condition, selections, parent_type, info)
    end)
  end

  defp conditionally_project(condition, selections, parent_type, %{schema: schema} = info) do
    condition
    |> Type.unwrap
    |> normalize_condition(schema)
    |> passes_type_condition?(parent_type)
    |> case do
      true -> project(selections, info)
      false -> []
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
