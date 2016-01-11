defmodule Absinthe.Introspection.Field do

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
      end
    }
  end

  def meta("type") do
    %Type.Field{
      name: "__Type",
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


end
