defmodule Absinthe.Introspection.Types do

  @moduledoc false

  use Absinthe.Type.Definitions
  alias Absinthe.Flag
  alias Absinthe.Language
  alias Absinthe.Type

  @absinthe :type
  def __schema do
    %Type.Object{
      name: "__Type",
      description: "Represents a schema",
      fields: fields(
        types: [
          type: list_of(:__type),
          resolve: fn
            _, %{schema: schema} ->
              schema.types.by_identifier
              |> Map.values
              |> Enum.filter(&(!match?("__" <> _, &1.name)))
              |> Flag.as(:ok)
          end
        ],
        query_type: [
          type: :__type,
          resolve: fn
            _, %{schema: schema} ->
              {:ok, schema.query}
          end
        ],
        mutation_type: [
          type: :__type,
          resolve: fn
            _, %{schema: schema} ->
              {:ok, schema.mutation}
          end
        ],
        directives: [
          type: list_of(:__directive),
          resolve: fn
            _, %{schema: schema} ->
              structs = schema.directives |> Map.values
              {:ok, structs}
          end
        ]
      )
    }
  end

  @absinthe :type
  def __directive do
    %Type.Object{
      name: "__Directive",
      description: "Represents a directive",
      fields: fields(
        name: [type: :string],
        description: [type: :string],
        args: [
          type: list_of(:__inputvalue),
          resolve: fn
            _, %{resolution: %{target: target}} ->
              structs = target.args |> Map.values
              {:ok, structs}
          end
        ],
        on_operation: [
          type: :boolean,
          resolve: fn
            _, %{resolution: %{target: target}} ->
              {:ok, Enum.member?(target.on, Language.OperationDefinition)}
          end
        ],
        on_fragment: [
          type: :boolean,
          resolve: fn
            _, %{resolution: %{target: target}} ->
              {:ok, Enum.member?(target.on, Language.FragmentSpread)}
          end
        ],
        on_field: [
          type: :boolean,
          resolve: fn
            _, %{resolution: %{target: target}} ->
              {:ok, Enum.member?(target.on, Language.Field)}
          end
        ]
      )
    }
  end

  @absinthe :type
  def __type do
    %Type.Object{
      name: "__Type",
      description: "Represents scalars, interfaces, object types, unions, enums in the system",
      fields: fields(
        kind: [
          type: :string,
          resolve: fn
            _, %{resolution: %{target: %{__struct__: type}}} ->
              {:ok, type.kind}
          end
        ],
        name: [type: :string],
        description: [type: :string],
        fields: [
          type: list_of(:__field),
          args: args(
            include_deprecated: [
              type: :boolean,
              default_value: false
            ]
          ),
          resolve: fn
            %{include_deprecated: show_deprecated}, %{resolution: %{target: %{__struct__: str, fields: fields}}} when str in [Type.Object, Type.Interface] ->
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
        ],
        interfaces: [
          type: list_of(:__type),
          resolve: fn
            _, %{schema: schema, resolution: %{target: %{interfaces: interfaces}}} ->
              structs = interfaces
              |> Enum.map(fn
                ident -> schema.types[ident]
              end)
              {:ok, structs}
            _, _ ->
              {:ok, nil}
          end
        ],
        possible_types: [
          type: list_of(:__type),
          resolve: fn
            _, %{schema: schema, resolution: %{target: %Type.Union{types: types}}} ->
              structs = types |> Enum.map(&(Absinthe.Schema.lookup_type(schema, &1)))
              {:ok, structs}
            _, %{schema: schema, resolution: %{target: %Type.Interface{reference: %{identifier: ident}}}} ->
              implementors = schema.interfaces[ident]
              structs = implementors |> Enum.map(fn name -> schema.types[name] end)
              {:ok, structs}
            _, _ ->
              {:ok, nil}
          end
        ],
        enum_values: [
          type: list_of(:__enumvalue),
          args: args(
            include_deprecated: [
              type: :boolean,
              default_value: false
            ]
          ),
          resolve: fn
            %{include_deprecated: show_deprecated}, %{resolution: %{target: %Type.Enum{values: values}}} ->
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
        ],
        input_fields: [
          type: list_of(:__inputvalue),
          resolve: fn
            _, %{resolution: %{target: %Type.InputObject{fields: fields}}} ->
              structs = fields |> Map.values
              {:ok, structs}
            _, _ ->
              {:ok, nil}
          end
        ],
        of_type: [
          type: :__type,
          resolve: fn
            _, %{schema: schema, resolution: %{target: %{of_type: type}}} ->
              Absinthe.Schema.lookup_type(schema, type, unwrap: false)
              |> Flag.as(:ok)
            _, _ ->
              {:ok, nil}
          end
        ]
      )
    }
  end

  @absinthe :type
  def __field do
    %Type.Object{
      name: "__Field",
      fields: fields(
        name: [
          type: :string,
          resolve: fn
            _, %{adapter: adapter, resolution: %{target: target}} ->
              target.name
              |> adapter.to_external_name(:field)
              |> Flag.as(:ok)
          end
        ],
        description: [type: :string],
        args: [
          type: list_of(:__inputvalue),
          resolve: fn
            _, %{resolution: %{target: target}} ->
              structs = target.args |> Map.values
              {:ok, structs}
          end
        ],
        type: [
          type: :__type,
          resolve: fn
            _, %{schema: schema, resolution: %{target: target}} ->
              case target.type do
                type when is_atom(type) ->
                  Absinthe.Schema.lookup_type(schema, target.type)
                type ->
                  type
              end
              |> Flag.as(:ok)
          end
        ],
        is_deprecated: [
          type: :boolean,
          resolve: fn
            _, %{resolution: %{target: %{deprecation: nil}}} ->
              {:ok, false}
            _, _ ->
              {:ok, true}
          end
        ],
        deprecation_reason: [
          type: :string,
          resolve: fn
            _, %{resolution: %{target: %{deprecation: nil}}} ->
              {:ok, nil}
            _, %{resolution: %{target: %{deprecation: dep}}} ->
              {:ok, dep.reason}
          end
        ]
      )
    }
  end

  @absinthe :type
  def __inputvalue do
    %Type.Object{
      name: "__InputValue",
      fields: fields(
        name: [
          type: :string,
          resolve: fn
            _, %{adapter: adapter, resolution: %{target: target}} ->
              target.name
              |> adapter.to_external_name(:field)
              |> Flag.as(:ok)
          end
        ],
        description: [type: :string],
        type: [
          type: :__type,
          resolve: fn
            _, %{schema: schema, resolution: %{target: %{type: ident}}} ->
              type = Absinthe.Schema.lookup_type(schema, ident, unwrap: false)
              {:ok, type}
          end
        ],
        default_value: [
          type: :string,
          resolve: fn
            _, %{resolution: %{target: %{default_value: nil}}} ->
              {:ok, nil}
            _, %{resolution: %{target: %{default_value: value}}} ->
              {:ok, value |> to_string}
            _, %{resolution: %{target: _}} ->
              {:ok, nil}
          end
        ]
      )
    }
  end

  @absinthe :type
  def __enumvalue do
    %Type.Object{
      name: "__EnumValue",
      fields: fields(
        name: [type: :string],
        description: [type: :string],
        is_deprecated: [
          type: :boolean,
          resolve: fn
            _, %{resolution: %{target: %{deprecation: nil}}} ->
              {:ok, false}
            _, _ ->
              {:ok, true}
          end
        ],
        deprecation_reason: [
          type: :string,
          resolve: fn
            _, %{resolution: %{target: %{deprecation: nil}}} ->
              {:ok, nil}
            _, %{resolution: %{target: %{deprecation: dep}}} ->
              {:ok, dep.reason}
          end
        ]
      )
    }
  end

end
