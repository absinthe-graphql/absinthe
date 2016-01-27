defmodule Absinthe.Introspection.Field do

  @moduledoc false

  use Absinthe.Type.Definitions
  alias Absinthe.Type

  def meta("typename") do
    %Type.Field{
      name: "__typename",
      type: :string,
      description: "The name of the object type currently being queried.",
      resolve: fn
        _, %{resolution: %{parent_type: %Type.Object{} = type}} ->
          {:ok, type.name}
        _, %{resolution: %{target: target, parent_type: %Type.Interface{} = iface}} = exe ->
          case Type.Interface.resolve_type(iface, target, exe) do
            nil ->
              {:error, "Could not resolve type of concrete " <> iface.name}
            type ->
              {:ok, type.name}
          end
        _, %{resolution: %{target: target, parent_type: %Type.Union{} = union}} = exe ->
          case Type.Union.resolve_type(union, target, exe) do
            nil ->
              {:error, "Could not resolve type of concrete " <> union.name}
            type ->
              {:ok, type.name}
          end
      end
    }
  end

  def meta("type") do
    %Type.Field{
      name: "__type",
      type: :__type,
      description: "Represents scalars, interfaces, object types, unions, enums in the system",
      args: args(
        name: [
          type: non_null(:string),
          describe: "The name of the type to introspect"
        ],
      ),
      resolve: fn
        %{name: name}, %{schema: schema} ->
          {:ok, schema.types.by_name[name]}
      end
    }
  end

  def meta("schema") do
    %Type.Field{
      name: "__schema",
      type: :__schema,
      description: "Represents the schema",
      resolve: fn
        _, %{schema: schema} ->
          {:ok, schema}
      end
    }
  end

end
