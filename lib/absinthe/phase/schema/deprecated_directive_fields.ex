defmodule Absinthe.Phase.Schema.DeprecatedDirectiveFields do
  @moduledoc false
  # The spec of Oct 2015 has the onOperation, onFragment and onField
  # fields for directives (https://spec.graphql.org/October2015/#sec-Schema-Introspection)
  # See https://github.com/graphql/graphql-spec/pull/152 for the rationale.
  # These fields are deprecated and can be removed in the future.
  alias Absinthe.Blueprint

  use Absinthe.Schema.Notation

  @behaviour Absinthe.Phase

  def run(input, _options \\ []) do
    blueprint = Blueprint.prewalk(input, &handle_node/1)

    {:ok, blueprint}
  end

  defp handle_node(%Blueprint.Schema.ObjectTypeDefinition{identifier: :__directive} = node) do
    [types] = __MODULE__.__absinthe_blueprint__().schema_definitions

    new_node = Enum.find(types.type_definitions, &(&1.identifier == :deprecated_directive_fields))

    fields = node.fields ++ new_node.fields

    %{node | fields: fields}
  end

  defp handle_node(node) do
    node
  end

  object :deprecated_directive_fields do
    field :on_operation, :boolean do
      deprecate "Check `locations` field for enum value OPERATION"

      resolve fn _, %{source: source} ->
        {:ok, Enum.any?(source.locations, &Enum.member?([:query, :mutation, :subscription], &1))}
      end
    end

    field :on_fragment, :boolean do
      deprecate "Check `locations` field for enum value FRAGMENT_SPREAD"

      resolve fn _, %{source: source} ->
        {:ok, Enum.member?(source.locations, :fragment_spread)}
      end
    end

    field :on_field, :boolean do
      deprecate "Check `locations` field for enum value FIELD"

      resolve fn _, %{source: source} ->
        {:ok, Enum.member?(source.locations, :field)}
      end
    end
  end
end
