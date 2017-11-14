defmodule Absinthe.Type.BuiltIns.Introspection do
  @moduledoc false

  use Absinthe.Schema.Notation

  object :__schema do
    description "Represents a schema"

    field :types, list_of(:__type) do
      complexity 0
      resolve fn
        _, %{schema: schema} ->
          {:ok, Absinthe.Schema.used_types(schema) ++ Absinthe.Schema.introspection_types(schema)}
      end
    end

    field :query_type,
      complexity: 0,
      type: :__type,
      resolve: fn
        _, %{schema: schema} ->
          {:ok, Absinthe.Schema.lookup_type(schema, :query)}
      end

    field :mutation_type,
      complexity: 0,
      type: :__type,
      resolve: fn
        _, %{schema: schema} ->
          {:ok, Absinthe.Schema.lookup_type(schema, :mutation)}
      end

    field :subscription_type,
      complexity: 0,
      type: :__type,
      resolve: fn
        _, %{schema: schema} ->
          {:ok, Absinthe.Schema.lookup_type(schema, :subscription)}
      end

    field :directives,
      complexity: 0,
      type: list_of(:__directive),
      resolve: fn
        _, %{schema: schema} ->
          {:ok, Absinthe.Schema.directives(schema)}
      end

  end

  object :__directive do
    description "Represents a directive"

    field :name, :string, complexity: 0

    field :description, :string, complexity: 0

    field :args,
      complexity: 0,
      type: list_of(:__inputvalue),
      resolve: fn
        _, %{source: source} ->
          structs = source.args |> Map.values
          {:ok, structs}
      end

    field :on_operation,
      complexity: 0,
      deprecate: "Check `locations` field for enum value OPERATION",
      type: :boolean,
      resolve: fn
        _, %{source: source} ->
          {:ok, Enum.any?(source.locations, &Enum.member?([:query, :mutation, :subscription], &1))}
      end

    field :on_fragment,
      complexity: 0,
      deprecate: "Check `locations` field for enum value FRAGMENT_SPREAD",
      type: :boolean,
      resolve: fn
        _, %{source: source} ->
          {:ok, Enum.member?(source.locations, :fragment_spread)}
      end

    field :on_field,
      complexity: 0,
      type: :boolean,
      deprecate: "Check `locations` field for enum value FIELD",
      resolve: fn
        _, %{source: source} ->
          {:ok, Enum.member?(source.locations, :field)}
      end

    field :locations, list_of(:__directive_location), complexity: 0

  end

  enum :__directive_location, values: [
    # OPERATIONS
    :query,
    :mutation,
    :subscription,
    :field,
    :fragment_definition,
    :fragment_spread,
    :inline_fragment
    # TODO: Schema definitions to support Schema input
  ]

  object :__type do
    description "Represents scalars, interfaces, object types, unions, enums in the system"

    field :kind,
      complexity: 0,
      type: :string,
      resolve: fn
        _, %{source: %{__struct__: type}} ->
          {:ok, type.kind}
      end

    field :name, :string, complexity: 0

    field :description, :string, complexity: 0

    field :fields, list_of(:__field) do
      complexity 0
      arg :include_deprecated, :boolean, default_value: false
      resolve fn
        %{include_deprecated: show_deprecated}, %{source: %{__struct__: str, fields: fields}} when str in [Absinthe.Type.Object, Absinthe.Type.Interface] ->
          result = fields
          |> Enum.flat_map(fn
            {_, %{deprecation: is_deprecated} = field} ->
            if !is_deprecated || (is_deprecated && show_deprecated) do
              [field]
            else
              []
            end
          end)
          {:ok, result}
        _, _ ->
          {:ok, nil}
      end
    end

    field :interfaces,
      complexity: 0,
      type: list_of(:__type),
      resolve: fn
        _, %{schema: schema, source: %{interfaces: interfaces}} ->
          structs = interfaces
          |> Enum.map(fn
            ident ->
              Absinthe.Schema.lookup_type(schema, ident)
          end)
          {:ok, structs}
        _, _ ->
          {:ok, nil}
      end

    field :possible_types,
      complexity: 0,
      type: list_of(:__type),
      resolve: fn
        _, %{schema: schema, source: %{types: types}} ->
          structs = types |> Enum.map(&(Absinthe.Schema.lookup_type(schema, &1)))
          {:ok, structs}
        _, %{schema: schema, source: %Absinthe.Type.Interface{__reference__: %{identifier: ident}}} ->
          {:ok, Absinthe.Schema.implementors(schema, ident)}
        _, _ ->
          {:ok, nil}
      end

    field :enum_values,
      complexity: 0,
      type: list_of(:__enumvalue),
      args: [
        include_deprecated: [
          type: :boolean,
          default_value: false
        ]
      ],
      resolve: fn
        %{include_deprecated: show_deprecated}, %{source: %Absinthe.Type.Enum{values: values}} ->
          result = values
          |> Enum.flat_map(fn
            {_, %{deprecation: is_deprecated} = value} ->
              if !is_deprecated || (is_deprecated && show_deprecated) do
                [value]
              else
                []
              end
          end)
          {:ok, result}
        _, _ ->
          {:ok, nil}
      end

    field :input_fields,
      complexity: 0,
      type: list_of(:__inputvalue),
      resolve: fn
        _, %{source: %Absinthe.Type.InputObject{fields: fields}} ->
          structs = fields |> Map.values
          {:ok, structs}
        _, %{source: _} ->
          {:ok, nil}
      end

    field :of_type,
      complexity: 0,
      type: :__type,
      resolve: fn
        _, %{schema: schema, source: %{of_type: type}} ->
          {:ok, Absinthe.Schema.lookup_type(schema, type, unwrap: false)}
        _, _ ->
          {:ok, nil}
      end

  end

  object :__field do

    field :name,
      complexity: 0,
      type: :string,
      resolve: fn
        _, %{adapter: adapter, source: source} ->
          {:ok, adapter.to_external_name(source.name, :field)}
      end

    field :description, :string, complexity: 0

    field :args,
      complexity: 0,
      type: list_of(:__inputvalue),
      resolve: fn
        _, %{source: source} ->
          {:ok, Map.values(source.args)}
      end

    field :type,
      complexity: 0,
      type: :__type,
      resolve: fn
        _, %{schema: schema, source: source} ->
          result = case source.type do
            type when is_atom(type) ->
              Absinthe.Schema.lookup_type(schema, source.type)
            type ->
              type
          end
          {:ok, result}
      end

    field :is_deprecated,
      complexity: 0,
      type: :boolean,
      resolve: fn
        _, %{source: %{deprecation: nil}} ->
          {:ok, false}
        _, _ ->
          {:ok, true}
      end

    field :deprecation_reason,
      complexity: 0,
      type: :string,
      resolve: fn
        _, %{source: %{deprecation: nil}} ->
          {:ok, nil}
        _, %{source: %{deprecation: dep}} ->
          {:ok, dep.reason}
      end

  end

  object :__inputvalue, name: "__InputValue" do

    field :name,
      complexity: 0,
      type: :string,
      resolve: fn
        _, %{adapter: adapter, source: source} ->
          {:ok, adapter.to_external_name(source.name, :field)}
      end

    field :description, :string, complexity: 0
    field :type,
      complexity: 0,
      type: :__type,
      resolve: fn
        _, %{schema: schema, source: %{type: ident}} ->
          type = Absinthe.Schema.lookup_type(schema, ident, unwrap: false)
          {:ok, type}
      end

    field :default_value,
      complexity: 0,
      type: :string,
      resolve: fn
        _, %{source: %{default_value: nil}} ->
          {:ok, nil}

        _, %{schema: schema, source: %{default_value: value, type: type}} ->
          case Absinthe.Schema.lookup_type(schema, type, unwrap: true) do
            %Absinthe.Type.Enum{values_by_internal_value: values} ->
              {:ok, values[value].name}
            %{serialize: serializer} ->
              {:ok, inspect serializer.(value)}
            _ ->
              {:ok, to_string(value)}
          end

        _, %{source: _} ->
          {:ok, nil}
      end

  end

  object :__enumvalue, name: "__EnumValue" do

    field :name, :string, complexity: 0

    field :description, :string, complexity: 0

    field :is_deprecated,
      complexity: 0,
      type: :boolean,
      resolve: fn
        _, %{source: %{deprecation: nil}} ->
          {:ok, false}
        _, _ ->
          {:ok, true}
      end

    field :deprecation_reason,
      complexity: 0,
      type: :string,
      resolve: fn
        _, %{source: %{deprecation: nil}} ->
          {:ok, nil}
        _, %{source: %{deprecation: dep}} ->
          {:ok, dep.reason}
      end

  end

end
