defmodule Absinthe.Introspection.Field do
  @moduledoc false

  use Absinthe.Schema.Notation

  alias Absinthe.Schema
  alias Absinthe.Type

  def meta("typename") do
    %Type.Field{
      name: "__typename",
      type: :string,
      description: "The name of the object type currently being queried.",
      middleware: [
        Absinthe.Resolution.resolver_spec(fn
          _, %{parent_type: %Type.Object{} = type} ->
            {:ok, type.name}

          _, %{source: source, parent_type: %Type.Interface{} = iface} = env ->
            case Type.Interface.resolve_type(iface, source, env) do
              nil ->
                {:error, "Could not resolve type of concrete " <> iface.name}

              type ->
                {:ok, type.name}
            end

          _, %{source: source, parent_type: %Type.Union{} = union} = env ->
            case Type.Union.resolve_type(union, source, env) do
              nil ->
                {:error, "Could not resolve type of concrete " <> union.name}

              type ->
                {:ok, type.name}
            end
        end)
      ]
    }
  end

  def meta("type") do
    %Type.Field{
      name: "__type",
      type: :__type,
      description: "Represents scalars, interfaces, object types, unions, enums in the system",
      args: %{
        name: %Type.Argument{
          name: "name",
          type: non_null(:string),
          description: "The name of the type to introspect",
          __reference__: %{
            identifier: :name
          }
        }
      },
      middleware: [
        Absinthe.Resolution.resolver_spec(fn %{name: name}, %{schema: schema} ->
          {:ok, Schema.lookup_type(schema, name)}
        end)
      ]
    }
  end

  def meta("schema") do
    %Type.Field{
      name: "__schema",
      type: :__schema,
      description: "Represents the schema",
      middleware: [
        Absinthe.Resolution.resolver_spec(fn _, %{schema: schema} ->
          {:ok, schema}
        end)
      ]
    }
  end
end
