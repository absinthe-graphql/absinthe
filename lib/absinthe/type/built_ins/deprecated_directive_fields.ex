defmodule Absinthe.Type.BuiltIns.DeprecatedDirectiveFields do
  @moduledoc false
  # The spec of Oct 2015 has the onOperation, onFragment and onField
  # fields for directives (https://spec.graphql.org/October2015/#sec-Schema-Introspection)
  # See https://github.com/graphql/graphql-spec/pull/152 for the rationale.
  # These fields are deprecated and can be removed in the future.

  use Absinthe.Schema.Notation

  extend object(:__directive) do
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
