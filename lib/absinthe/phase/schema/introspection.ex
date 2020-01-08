defmodule Absinthe.Phase.Schema.Introspection do
  @moduledoc false

  use Absinthe.Phase
  alias Absinthe.Blueprint

  alias Absinthe.Blueprint.Schema.FieldDefinition
  alias Absinthe.Blueprint.Schema.InputValueDefinition
  alias Absinthe.Blueprint.TypeReference.NonNull
  alias Absinthe.Blueprint.Schema.ObjectTypeDefinition
  alias Absinthe.Blueprint.Schema.ListTypeDefinition
  alias Absinthe.Blueprint.Schema.UnionTypeDefinition
  alias Absinthe.Blueprint.Schema.InterfaceTypeDefinition

  def __absinthe_function__(identifier, :middleware) do
    [{{Absinthe.Resolution, :call}, resolve_fn(identifier)}]
  end

  def run(blueprint, _opts) do
    blueprint = attach_introspection_fields(blueprint)
    {:ok, blueprint}
  end

  @doc """
  Append the given field or fields to the given type
  """
  def attach_introspection_fields(blueprint = %Blueprint{}) do
    %{blueprint | schema_definitions: update_schema_defs(blueprint.schema_definitions)}
  end

  def update_schema_defs(schema_definitions) do
    for schema_def = %{type_definitions: type_defs} <- schema_definitions do
      %{schema_def | type_definitions: update_type_defs(type_defs)}
    end
  end

  def update_type_defs(type_defs) do
    for type_def = %struct_type{} <- type_defs do
      cond do
        type_def.name in ["RootQueryType", "Query"] ->
          type_field = field_def(:type)
          schema_field = field_def(:schema)
          typename_field = field_def(:typename)
          %{type_def | fields: [type_field, schema_field, typename_field | type_def.fields]}

        struct_type in [
          ObjectTypeDefinition,
          ListTypeDefinition,
          UnionTypeDefinition,
          InterfaceTypeDefinition
        ] ->
          typename_field = field_def(:typename)
          %{type_def | fields: [typename_field | type_def.fields]}

        true ->
          type_def
      end
    end
  end

  def field_def(:typename) do
    %FieldDefinition{
      name: "__typename",
      identifier: :__typename,
      module: __MODULE__,
      type: :string,
      description: "The name of the object type currently being queried.",
      complexity: 0,
      triggers: %{},
      middleware: [
        {:ref, __MODULE__, :typename}
      ],
      flags: %{reserved_name: true},
      __reference__: Absinthe.Schema.Notation.build_reference(__ENV__)
    }
  end

  def field_def(:type) do
    %FieldDefinition{
      __reference__: Absinthe.Schema.Notation.build_reference(__ENV__),
      name: "__type",
      identifier: :__type,
      type: :__type,
      module: __MODULE__,
      description: "Represents scalars, interfaces, object types, unions, enums in the system",
      triggers: %{},
      arguments: [
        %InputValueDefinition{
          __reference__: Absinthe.Schema.Notation.build_reference(__ENV__),
          module: __MODULE__,
          identifier: :name,
          name: "name",
          type: %NonNull{of_type: :string},
          description: "The name of the type to introspect"
        }
      ],
      middleware: [
        {:ref, __MODULE__, :type}
      ],
      flags: %{reserved_name: true}
    }
  end

  def field_def(:schema) do
    %FieldDefinition{
      name: "__schema",
      identifier: :__schema,
      type: :__schema,
      module: __MODULE__,
      description: "Represents the schema",
      triggers: %{},
      middleware: [
        {:ref, __MODULE__, :schema}
      ],
      flags: %{reserved_name: true},
      __reference__: Absinthe.Schema.Notation.build_reference(__ENV__)
    }
  end

  def resolve_fn(:schema) do
    fn _, %{schema: schema} ->
      {:ok, schema}
    end
  end

  def resolve_fn(:type) do
    fn %{name: name}, %{schema: schema} ->
      type_def =
        case Absinthe.Schema.lookup_type(schema, name) do
          type_def = %{fields: fields} ->
            %{type_def | fields: filter_fields(fields)}

          type_def ->
            type_def
        end

      {:ok, type_def}
    end
  end

  def resolve_fn(:typename) do
    fn
      _, %{parent_type: %Absinthe.Type.Object{} = type} ->
        {:ok, type.name}

      _, %{source: source, parent_type: %Absinthe.Type.Interface{} = iface} = env ->
        case Absinthe.Type.Interface.resolve_type(iface, source, env) do
          nil ->
            {:error, "Could not resolve type of concrete " <> iface.name}

          type ->
            {:ok, type.name}
        end

      _, %{source: source, parent_type: %Absinthe.Type.Union{} = union} = env ->
        case Absinthe.Type.Union.resolve_type(union, source, env) do
          nil ->
            {:error, "Could not resolve type of concrete " <> union.name}

          type ->
            {:ok, type.name}
        end
    end
  end

  def filter_fields(fields) do
    for {key, field = %{name: name}} <- fields, not String.starts_with?(name, "__"), into: %{} do
      {key, field}
    end
  end
end
