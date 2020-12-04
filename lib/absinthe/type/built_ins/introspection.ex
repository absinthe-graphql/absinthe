defmodule Absinthe.Type.BuiltIns.Introspection do
  @moduledoc false

  use Absinthe.Schema.Notation

  object :__schema do
    description "Represents a schema"

    field :types, list_of(:__type) do
      resolve fn _, %{schema: schema} ->
        types =
          Absinthe.Schema.types(schema)
          |> Enum.sort_by(& &1.identifier)

        {:ok, types}
      end
    end

    field :query_type,
      type: :__type,
      resolve: fn _, %{schema: schema} ->
        {:ok, Absinthe.Schema.lookup_type(schema, :query)}
      end

    field :mutation_type,
      type: :__type,
      resolve: fn _, %{schema: schema} ->
        {:ok, Absinthe.Schema.lookup_type(schema, :mutation)}
      end

    field :subscription_type,
      type: :__type,
      resolve: fn _, %{schema: schema} ->
        {:ok, Absinthe.Schema.lookup_type(schema, :subscription)}
      end

    field :directives,
      type: list_of(:__directive),
      resolve: fn _, %{schema: schema} ->
        directives =
          Absinthe.Schema.directives(schema)
          |> Enum.sort_by(& &1.identifier)

        {:ok, directives}
      end
  end

  object :__directive do
    description "Represents a directive"

    field :name, :string

    field :description, :string

    field :is_repeatable, :boolean,
      resolve: fn _, %{source: source} ->
        {:ok, source.repeatable}
      end

    field :args,
      type: list_of(:__inputvalue),
      resolve: fn _, %{source: source} ->
        args =
          source.args
          |> Map.values()
          |> Enum.sort_by(& &1.identifier)

        {:ok, args}
      end

    field :on_operation,
      deprecate: "Check `locations` field for enum value OPERATION",
      type: :boolean,
      resolve: fn _, %{source: source} ->
        {:ok, Enum.any?(source.locations, &Enum.member?([:query, :mutation, :subscription], &1))}
      end

    field :on_fragment,
      deprecate: "Check `locations` field for enum value FRAGMENT_SPREAD",
      type: :boolean,
      resolve: fn _, %{source: source} ->
        {:ok, Enum.member?(source.locations, :fragment_spread)}
      end

    field :on_field,
      type: :boolean,
      deprecate: "Check `locations` field for enum value FIELD",
      resolve: fn _, %{source: source} ->
        {:ok, Enum.member?(source.locations, :field)}
      end

    field :locations, list_of(:__directive_location)
  end

  enum :__directive_location,
    values: [
      :query,
      :mutation,
      :subscription,
      :field,
      :fragment_definition,
      :fragment_spread,
      :inline_fragment,
      :schema,
      :scalar,
      :object,
      :field_definition,
      :interface,
      :union,
      :enum,
      :enum_value,
      :input_object,
      :argument_definition,
      :input_field_definition
    ]

  object :__type do
    description "Represents scalars, interfaces, object types, unions, enums in the system"

    field :kind,
      type: :string,
      resolve: fn _, %{source: %{__struct__: type}} ->
        {:ok, type.kind}
      end

    field :name, :string

    field :description, :string

    field :fields, list_of(:__field) do
      arg :include_deprecated, :boolean, default_value: false

      resolve fn
        %{include_deprecated: show_deprecated}, %{source: %{__struct__: str, fields: fields}}
        when str in [Absinthe.Type.Object, Absinthe.Type.Interface] ->
          result =
            fields
            |> Enum.flat_map(fn {_, %{deprecation: is_deprecated} = field} ->
              cond do
                Absinthe.Type.introspection?(field) ->
                  []

                !is_deprecated || (is_deprecated && show_deprecated) ->
                  [field]

                true ->
                  []
              end
            end)
            |> Enum.sort_by(& &1.identifier)

          {:ok, result}

        _, _ ->
          {:ok, nil}
      end
    end

    field :interfaces,
      type: list_of(:__type),
      resolve: fn
        _, %{schema: schema, source: %{interfaces: interfaces}} ->
          interfaces =
            interfaces
            |> Enum.map(&Absinthe.Schema.lookup_type(schema, &1))
            |> Enum.sort_by(& &1.identifier)

          {:ok, interfaces}

        _, _ ->
          {:ok, nil}
      end

    field :possible_types,
      type: list_of(:__type),
      resolve: fn
        _, %{schema: schema, source: %{types: types}} ->
          possible_types =
            types
            |> Enum.map(&Absinthe.Schema.lookup_type(schema, &1))
            |> Enum.sort_by(& &1.identifier)

          {:ok, possible_types}

        _, %{schema: schema, source: %Absinthe.Type.Interface{identifier: ident}} ->
          {:ok, Absinthe.Schema.implementors(schema, ident)}

        _, _ ->
          {:ok, nil}
      end

    field :enum_values,
      type: list_of(:__enumvalue),
      args: [
        include_deprecated: [
          type: :boolean,
          default_value: false
        ]
      ],
      resolve: fn
        %{include_deprecated: show_deprecated}, %{source: %Absinthe.Type.Enum{values: values}} ->
          result =
            values
            |> Enum.flat_map(fn {_, %{deprecation: is_deprecated} = value} ->
              if !is_deprecated || (is_deprecated && show_deprecated) do
                [value]
              else
                []
              end
            end)
            |> Enum.sort_by(& &1.value)

          {:ok, result}

        _, _ ->
          {:ok, nil}
      end

    field :input_fields,
      type: list_of(:__inputvalue),
      resolve: fn
        _, %{source: %Absinthe.Type.InputObject{fields: fields}} ->
          input_fields =
            fields
            |> Map.values()
            |> Enum.sort_by(& &1.identifier)

          {:ok, input_fields}

        _, %{source: _} ->
          {:ok, nil}
      end

    field :of_type,
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
      type: :string,
      resolve: fn _, %{adapter: adapter, source: source} ->
        {:ok, adapter.to_external_name(source.name, :field)}
      end

    field :description, :string

    field :args,
      type: list_of(:__inputvalue),
      resolve: fn _, %{source: %{args: args}} ->
        args =
          args
          |> Map.values()
          |> Enum.sort_by(& &1.identifier)

        {:ok, args}
      end

    field :type,
      type: :__type,
      resolve: fn _, %{schema: schema, source: source} ->
        result =
          case source.type do
            type when is_atom(type) ->
              Absinthe.Schema.lookup_type(schema, source.type)

            type ->
              type
          end

        {:ok, result}
      end

    field :is_deprecated,
      type: :boolean,
      resolve: fn
        _, %{source: %{deprecation: nil}} ->
          {:ok, false}

        _, _ ->
          {:ok, true}
      end

    field :deprecation_reason,
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
      type: :string,
      resolve: fn _, %{adapter: adapter, source: source} ->
        {:ok, adapter.to_external_name(source.name, :field)}
      end

    field :description, :string

    field :type,
      type: :__type,
      resolve: fn _, %{schema: schema, source: %{type: ident}} ->
        type = Absinthe.Schema.lookup_type(schema, ident, unwrap: false)
        {:ok, type}
      end

    field :default_value,
      type: :string,
      resolve: fn
        _, %{source: %{default_value: nil}} ->
          {:ok, nil}

        _, %{schema: schema, source: %{default_value: value, type: type}, adapter: adapter} ->
          {:ok, render_default_value(schema, adapter, type, value)}

        _, %{source: _} ->
          {:ok, nil}
      end
  end

  object :__enumvalue, name: "__EnumValue" do
    field :name, :string

    field :description, :string

    field :is_deprecated,
      type: :boolean,
      resolve: fn
        _, %{source: %{deprecation: nil}} ->
          {:ok, false}

        _, _ ->
          {:ok, true}
      end

    field :deprecation_reason,
      type: :string,
      resolve: fn
        _, %{source: %{deprecation: nil}} ->
          {:ok, nil}

        _, %{source: %{deprecation: dep}} ->
          {:ok, dep.reason}
      end
  end

  def render_default_value(schema, adapter, type, value) do
    case Absinthe.Schema.lookup_type(schema, type, unwrap: false) do
      %Absinthe.Type.InputObject{fields: fields} ->
        object_values =
          fields
          |> Map.take(Map.keys(value))
          |> Map.values()
          |> Enum.map(&render_default_value(schema, adapter, &1, value))
          |> Enum.join(", ")

        "{#{object_values}}"

      %Absinthe.Type.List{of_type: type} ->
        list_values =
          value
          |> List.wrap()
          |> Enum.map(&render_default_value(schema, adapter, type, &1))
          |> Enum.join(", ")

        "[#{list_values}]"

      %Absinthe.Type.Field{type: type, name: name, identifier: identifier} ->
        key = adapter.to_external_name(name, :field)
        val = render_default_value(schema, adapter, type, value[identifier])
        "#{key}: #{val}"

      %Absinthe.Type.Enum{values_by_internal_value: values} ->
        values[value].name

      %Absinthe.Type.NonNull{of_type: type} ->
        render_default_value(schema, adapter, type, value)

      %Absinthe.Type.Scalar{} = sc ->
        inspect(Absinthe.Type.Scalar.serialize(sc, value))
    end
  end
end
