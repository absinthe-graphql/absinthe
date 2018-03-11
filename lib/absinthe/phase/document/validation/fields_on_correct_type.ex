defmodule Absinthe.Phase.Document.Validation.FieldsOnCorrectType do
  @moduledoc false

  # Validates document to ensure that all fields are provided on the correct type.

  alias Absinthe.{Blueprint, Phase, Schema, Type}

  use Absinthe.Phase

  @doc """
  Run the validation.
  """
  @spec run(Blueprint.t(), Keyword.t()) :: Phase.result_t()
  def run(input, _options \\ []) do
    result = Blueprint.prewalk(input, &handle_node(&1, input))
    {:ok, result}
  end

  @spec handle_node(Blueprint.node_t(), Schema.t()) :: Blueprint.node_t()
  defp handle_node(%Blueprint.Document.Operation{schema_node: nil} = node, _) do
    error = %Phase.Error{
      phase: __MODULE__,
      message: "Operation \"#{node.type}\" not supported",
      locations: [node.source_location]
    }

    node
    |> flag_invalid(:unknown_operation)
    |> put_error(error)
  end

  defp handle_node(
         %{selections: selections, schema_node: parent_schema_node} = node,
         %{schema: schema} = input
       )
       when not is_nil(parent_schema_node) do
    possible_parent_types = possible_types(parent_schema_node, schema)

    selections =
      Enum.map(selections, fn
        %Blueprint.Document.Field{schema_node: nil} = field ->
          type = named_type(parent_schema_node, schema)

          field
          |> flag_invalid(:unknown_field)
          |> put_error(
            error(
              field,
              type.name,
              suggested_type_names(field.name, type, input),
              suggested_field_names(field.name, type, input)
            )
          )

        %Blueprint.Document.Fragment.Spread{errors: []} = spread ->
          fragment = Enum.find(input.fragments, &(&1.name == spread.name))
          possible_child_types = possible_types(fragment.schema_node, schema)

          if Enum.any?(possible_child_types, &(&1 in possible_parent_types)) do
            spread
          else
            spread_error(spread, possible_parent_types, possible_child_types, schema)
          end

        %Blueprint.Document.Fragment.Inline{} = fragment ->
          possible_child_types = possible_types(fragment.schema_node, schema)

          if Enum.any?(possible_child_types, &(&1 in possible_parent_types)) do
            fragment
          else
            spread_error(fragment, possible_parent_types, possible_child_types, schema)
          end

        other ->
          other
      end)

    %{node | selections: selections}
  end

  defp handle_node(node, _) do
    node
  end

  defp idents_to_names(idents, schema) do
    for ident <- idents do
      Absinthe.Schema.lookup_type(schema, ident).name
    end
  end

  defp spread_error(spread, parent_types_idents, child_types_idents, schema) do
    parent_types = idents_to_names(parent_types_idents, schema)
    child_types = idents_to_names(child_types_idents, schema)

    msg = """
    Fragment spread has no type overlap with parent.
    Parent possible types: #{inspect(parent_types)}
    Spread possible types: #{inspect(child_types)}
    """

    error = %Phase.Error{
      phase: __MODULE__,
      message: msg,
      locations: [spread.source_location]
    }

    spread
    |> flag_invalid(:invalid_spread)
    |> put_error(error)
  end

  defp possible_types(%{type: type}, schema) do
    possible_types(type, schema)
  end

  defp possible_types(type, schema) do
    schema
    |> Absinthe.Schema.lookup_type(type)
    |> case do
      %Type.Object{identifier: identifier} ->
        [identifier]

      %Type.Interface{__reference__: %{identifier: identifier}} ->
        schema.__absinthe_interface_implementors__
        |> Map.fetch!(identifier)

      %Type.Union{types: types} ->
        types

      _ ->
        []
    end
  end

  @spec named_type(Type.t(), Schema.t()) :: Type.named_t()
  defp named_type(%Type.Field{} = node, schema) do
    Schema.lookup_type(schema, node.type)
  end

  defp named_type(%{name: _} = node, _) do
    node
  end

  # Generate the error for a field
  @spec error(Blueprint.node_t(), String.t(), [String.t()], [String.t()]) :: Phase.Error.t()
  defp error(field_node, parent_type_name, type_suggestions, field_suggestions) do
    %Phase.Error{
      phase: __MODULE__,
      message:
        error_message(field_node.name, parent_type_name, type_suggestions, field_suggestions),
      locations: [field_node.source_location]
    }
  end

  @suggest 5

  @doc """
  Generate an error for a field
  """
  @spec error_message(String.t(), String.t(), [String.t()], [String.t()]) :: String.t()
  def error_message(field_name, type_name, type_suggestions \\ [], field_suggestions \\ [])

  def error_message(field_name, type_name, [], []) do
    ~s(Cannot query field "#{field_name}" on type "#{type_name}".)
  end

  def error_message(field_name, type_name, [], field_suggestions) do
    error_message(field_name, type_name) <>
      " Did you mean " <> to_quoted_or_list(field_suggestions |> Enum.take(@suggest)) <> "?"
  end

  def error_message(field_name, type_name, type_suggestions, []) do
    error_message(field_name, type_name) <>
      " Did you mean to use an inline fragment on " <>
      to_quoted_or_list(type_suggestions |> Enum.take(@suggest)) <> "?"
  end

  def error_message(field_name, type_name, type_suggestions, _) do
    error_message(field_name, type_name, type_suggestions)
  end

  defp suggested_type_names(external_field_name, type, blueprint) do
    internal_field_name = blueprint.adapter.to_internal_name(external_field_name, :field)
    possible_types = find_possible_types(internal_field_name, type, blueprint.schema)

    possible_interfaces =
      find_possible_interfaces(internal_field_name, possible_types, blueprint.schema)

    Enum.map(possible_interfaces, & &1.name) ++ Enum.map(possible_types, & &1.name)
  end

  defp suggested_field_names(external_field_name, %{fields: _} = type, blueprint) do
    internal_field_name = blueprint.adapter.to_internal_name(external_field_name, :field)

    Map.values(type.fields)
    |> Enum.map(& &1.name)
    |> Absinthe.Utils.Suggestion.sort_list(internal_field_name)
    |> Enum.map(&blueprint.adapter.to_external_name(&1, :field))
  end

  defp suggested_field_names(_, _, _) do
    []
  end

  defp find_possible_interfaces(field_name, possible_types, schema) do
    possible_types
    |> types_to_interface_idents
    |> Enum.uniq()
    |> sort_by_implementation_count(possible_types)
    |> Enum.map(&Schema.lookup_type(schema, &1))
    |> types_with_field(field_name)
  end

  defp sort_by_implementation_count(iface_idents, types) do
    Enum.sort_by(iface_idents, fn iface ->
      count =
        Enum.count(types, fn
          %{interfaces: ifaces} ->
            Enum.member?(ifaces, iface)

          _ ->
            false
        end)

      count
    end)
    |> Enum.reverse()
  end

  defp types_to_interface_idents(types) do
    Enum.flat_map(types, fn
      %{interfaces: ifaces} ->
        ifaces

      _ ->
        []
    end)
  end

  defp find_possible_types(field_name, type, schema) do
    schema
    |> Schema.concrete_types(Type.unwrap(type))
    |> types_with_field(field_name)
  end

  defp types_with_field(types, field_name) do
    Enum.filter(types, &type_with_field?(&1, field_name))
  end

  defp type_with_field?(%{fields: fields}, field_name) do
    Map.values(fields)
    |> Enum.find(&(&1.name == field_name))
  end

  defp type_with_field?(_, _) do
    false
  end

  defp to_quoted_or_list([a]), do: ~s("#{a}")
  defp to_quoted_or_list([a, b]), do: ~s("#{a}" or "#{b}")
  defp to_quoted_or_list(other), do: to_longer_quoted_or_list(other)

  defp to_longer_quoted_or_list(list, acc \\ "")
  defp to_longer_quoted_or_list([word], acc), do: acc <> ~s(, or "#{word}")

  defp to_longer_quoted_or_list([word | rest], "") do
    rest
    |> to_longer_quoted_or_list(~s("#{word}"))
  end

  defp to_longer_quoted_or_list([word | rest], acc) do
    rest
    |> to_longer_quoted_or_list(acc <> ~s(, "#{word}"))
  end
end
