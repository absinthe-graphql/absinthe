defmodule Absinthe.Resolution.Projector do

  alias Absinthe.{Blueprint, Type}

  def project(selections, info) do
    # TODO: cache this
    do_project(selections, info)
    |> refresh(info)
  end

  defp do_project(selections, %{fragments: fragments, parent_type: parent_type} = info) do
    Enum.flat_map(selections, fn
      %Blueprint.Document.Field{} = field ->
        [field]

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

  defp refresh(fields, %{parent_type: %{fields: concrete_fields}}) do
    for field <- fields do
      case field.name do
        "__" <> _ ->
          field
        _ ->
          %{field | schema_node: Map.fetch!(concrete_fields, field.schema_node.__reference__.identifier)}
      end
    end
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
