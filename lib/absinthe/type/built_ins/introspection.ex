defmodule Absinthe.Type.BuiltIns.Introspection do
  use Absinthe.Schema.Notation
  alias Absinthe.{Type, Schema, Flag, Language}

  @desc "Represents a schema"
  object :__schema do

    field :types, list_of(:__type) do
      resolve fn
        _, %{schema: schema} ->
          Schema.types(schema)
          |> Flag.as(:ok)
      end
    end

    field :query_type,
      type: :__type,
      resolve: fn
        _, %{schema: schema} ->
          {:ok, Schema.lookup_type(schema, :query)}
      end

    field :mutation_type,
      type: :__type,
      resolve: fn
        _, %{schema: schema} ->
          {:ok, Schema.lookup_type(schema, :mutation)}
      end

    field :directives,
      type: list_of(:__directive),
      resolve: fn
        _, %{schema: schema} ->
          {:ok, Schema.directives(schema)}
      end

  end

  @desc "Represents a directive"
  object :__directive do

    field :name, :string

    field :description, :string

    field :args,
      type: list_of(:__inputvalue),
      resolve: fn
        _, %{source: source} ->
          structs = source.args |> Map.values
          {:ok, structs}
      end

    field :on_operation,
      type: :boolean,
      resolve: fn
        _, %{source: source} ->
          {:ok, Enum.member?(source.on, Language.OperationDefinition)}
      end

    field :on_fragment,
      type: :boolean,
      resolve: fn
        _, %{source: source} ->
          {:ok, Enum.member?(source.on, Language.FragmentSpread)}
      end

    field :on_field,
      type: :boolean,
      resolve: fn
        _, %{source: source} ->
          {:ok, Enum.member?(source.on, Language.Field)}
      end

  end

  @desc "Represents scalars, interfaces, object types, unions, enums in the system"
  object :__type do

    field :kind,
      type: :string,
      resolve: fn
        _, %{source: %{__struct__: type}} ->
          {:ok, type.kind}
      end

    field :name, :string

    field :description, :string

    field :fields, list_of(:__field) do
      arg :include_deprecated, :boolean, default_value: false
      resolve fn
        %{include_deprecated: show_deprecated}, %{source: %{__struct__: str, fields: fields}} when str in [Type.Object, Type.Interface] ->
          fields
          |> Enum.flat_map(fn
            {_, %{deprecation: is_deprecated} = field} ->
            if !is_deprecated || (is_deprecated && show_deprecated) do
              [field]
            else
              []
            end
          end)
          |> Flag.as(:ok)
        _, _ ->
          {:ok, nil}
      end
    end

    field :interfaces,
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
      type: list_of(:__type),
      resolve: fn
        _, %{schema: schema, source: %{types: types}} ->
          structs = types |> Enum.map(&(Absinthe.Schema.lookup_type(schema, &1)))
          {:ok, structs}
        _, %{schema: schema, source: %Type.Interface{reference: %{identifier: ident}}} ->
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
        %{include_deprecated: show_deprecated}, %{source: %Type.Enum{values: values}} ->
          values
          |> Enum.flat_map(fn
            {_, %{deprecation: is_deprecated} = value} ->
              if !is_deprecated || (is_deprecated && show_deprecated) do
                [value]
              else
                []
              end
          end)
          |> Flag.as(:ok)
        _, _ ->
          {:ok, nil}
      end

    field :input_fields,
      type: list_of(:__inputvalue),
      resolve: fn
        _, %{source: %Type.InputObject{fields: fields}} ->
          structs = fields |> Map.values
          {:ok, structs}
        _, _ ->
          {:ok, nil}
      end

    field :of_type,
      type: :__type,
      resolve: fn
        _, %{schema: schema, source: %{of_type: type}} ->
          Absinthe.Schema.lookup_type(schema, type, unwrap: false)
          |> Flag.as(:ok)
        _, _ ->
          {:ok, nil}
      end

  end

  object :__field do

    field :name,
      type: :string,
      resolve: fn
        _, %{adapter: adapter, source: source} ->
          source.name
          |> adapter.to_external_name(:field)
          |> Flag.as(:ok)
      end

    field :description, :string

    field :args,
      type: list_of(:__inputvalue),
      resolve: fn
        _, %{source: source} ->
          {:ok, Map.values(source.args)}
      end

    field :type,
      type: :__type,
      resolve: fn
        _, %{schema: schema, source: source} ->
          case source.type do
            type when is_atom(type) ->
              Absinthe.Schema.lookup_type(schema, source.type)
            type ->
              type
          end
          |> Flag.as(:ok)
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
      resolve: fn
        _, %{adapter: adapter, source: source} ->
          source.name
          |> adapter.to_external_name(:field)
          |> Flag.as(:ok)
      end

    field :description, :string
    field :type,
      type: :__type,
      resolve: fn
        _, %{schema: schema, source: %{type: ident}} ->
          type = Absinthe.Schema.lookup_type(schema, ident, unwrap: false)
          {:ok, type}
      end

    field :default_value,
      type: :string,
      resolve: fn
        _, %{source: %{default_value: nil}} ->
          {:ok, nil}
        _, %{source: %{default_value: value}} ->
          {:ok, value |> to_string}
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

end
