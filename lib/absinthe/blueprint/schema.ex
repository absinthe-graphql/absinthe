defmodule Absinthe.Blueprint.Schema do
  @moduledoc false

  alias __MODULE__

  @type type_t ::
          Schema.EnumTypeDefinition.t()
          | Schema.InputObjectTypeDefinition.t()
          | Schema.InterfaceTypeDefinition.t()
          | Schema.ObjectTypeDefinition.t()
          | Schema.ScalarTypeDefinition.t()
          | Schema.UnionTypeDefinition.t()

  @type t :: type_t | Schema.DirectiveDefinition.t()

  @doc """
  Lookup a type definition that is part of a schema.
  """
  @spec lookup_type(Blueprint.t(), atom) :: nil | Blueprint.Schema.type_t()
  def lookup_type(blueprint, identifier) do
    blueprint.schema_definitions
    |> List.first()
    |> Map.get(:type_definitions)
    |> Enum.find(fn
      %{identifier: ^identifier} ->
        true

      _ ->
        false
    end)
  end

  def build([%Absinthe.Blueprint{} = bp | attrs]) do
    build_types(attrs, [bp])
  end

  defp build_types([], [bp]) do
    Map.update!(bp, :schema_definitions, &Enum.reverse/1)
  end

  defp build_types([%Schema.SchemaDefinition{} = schema | rest], stack) do
    build_types(rest, [schema | stack])
  end

  @simple_open [
    Schema.ScalarTypeDefinition,
    Schema.ObjectTypeDefinition,
    Schema.FieldDefinition,
    Schema.EnumTypeDefinition,
    Schema.DirectiveDefinition,
    Schema.InputObjectTypeDefinition,
    Schema.InterfaceTypeDefinition,
    Schema.UnionTypeDefinition,
    Schema.EnumValueDefinition
  ]

  defp build_types([%module{} = type | rest], stack) when module in @simple_open do
    build_types(rest, [type | stack])
  end

  defp build_types([{:import_fields, criterion} | rest], [obj | stack]) do
    build_types(rest, [push(obj, :imports, criterion) | stack])
  end

  defp build_types([{:desc, desc} | rest], [item | stack]) do
    build_types(rest, [%{item | description: desc} | stack])
  end

  defp build_types([{:middleware, middleware} | rest], [field | stack]) do
    field = Map.update!(field, :middleware, &(middleware ++ &1))
    build_types(rest, [field | stack])
  end

  defp build_types([{:config, config} | rest], [field | stack]) do
    field = %{field | config_ast: config}
    build_types(rest, [field | stack])
  end

  defp build_types([{:interface, interface} | rest], [obj | stack]) do
    obj = Map.update!(obj, :interfaces, &[interface | &1])
    build_types(rest, [obj | stack])
  end

  defp build_types([{:__private__, private} | rest], [entity | stack]) do
    entity = Map.update!(entity, :__private__, &update_private(&1, private))
    build_types(rest, [entity | stack])
  end

  defp build_types([{:values, values} | rest], [enum | stack]) do
    enum = Map.update!(enum, :values, &(values ++ &1))
    build_types(rest, [enum | stack])
  end

  defp build_types([%Schema.InputValueDefinition{} = arg | rest], [field | stack]) do
    build_types(rest, [push(field, :arguments, arg) | stack])
  end

  defp build_types([{:sdl, sdl_definitions} | rest], [schema | stack]) do
    # TODO: Handle directives, etc
    build_types(rest, [concat(schema, :type_definitions, sdl_definitions) | stack])
  end

  defp build_types([{attr, value} | rest], [entity | stack]) do
    entity = %{entity | attr => value}
    build_types(rest, [entity | stack])
  end

  defp build_types([:close | rest], [%Schema.EnumValueDefinition{} = value, enum | stack]) do
    build_types(rest, [push(enum, :values, value) | stack])
  end

  defp build_types([:close | rest], [%Schema.FieldDefinition{} = field, obj | stack]) do
    field = Map.update!(field, :middleware, &Enum.reverse/1)
    build_types(rest, [push(obj, :fields, field) | stack])
  end

  defp build_types([:close | rest], [%Schema.ObjectTypeDefinition{} = obj, schema | stack]) do
    obj = Map.update!(obj, :fields, &Enum.reverse/1)
    build_types(rest, [push(schema, :type_definitions, obj) | stack])
  end

  defp build_types([:close | rest], [%Schema.InputObjectTypeDefinition{} = obj, schema | stack]) do
    obj = Map.update!(obj, :fields, &Enum.reverse/1)
    build_types(rest, [push(schema, :type_definitions, obj) | stack])
  end

  defp build_types([:close | rest], [%Schema.InterfaceTypeDefinition{} = iface, schema | stack]) do
    iface = Map.update!(iface, :fields, &Enum.reverse/1)
    build_types(rest, [push(schema, :type_definitions, iface) | stack])
  end

  defp build_types([:close | rest], [%Schema.UnionTypeDefinition{} = union, schema | stack]) do
    build_types(rest, [push(schema, :type_definitions, union) | stack])
  end

  defp build_types([:close | rest], [%Schema.DirectiveDefinition{} = dir, schema | stack]) do
    build_types(rest, [push(schema, :directive_definitions, dir) | stack])
  end

  @simple_close [
    Schema.ScalarTypeDefinition,
    Schema.EnumTypeDefinition
  ]

  defp build_types([:close | rest], [%module{} = type, schema | stack])
       when module in @simple_close do
    schema = push(schema, :type_definitions, type)
    build_types(rest, [schema | stack])
  end

  defp build_types([:close | rest], [%Schema.SchemaDefinition{} = schema, bp]) do
    bp = push(bp, :schema_definitions, schema)
    build_types(rest, [bp])
  end

  defp push(entity, key, value) do
    Map.update!(entity, key, &[value | &1])
  end

  defp concat(entity, key, value) do
    Map.update!(entity, key, &(&1 ++ value))
  end

  defp update_private(existing_private, private) do
    Keyword.merge(existing_private, private, fn
      :meta, v1, v2 ->
        Keyword.merge(v1, v2)

      _, _, v2 ->
        v2
    end)
  end
end
