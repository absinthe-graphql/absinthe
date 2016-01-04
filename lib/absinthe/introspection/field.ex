defmodule Absinthe.Introspection.Field do

  alias Absinthe.Type

  # TODO: Support __schema, and __type
  def meta("typename") do
    %Type.Field{
      name: "__typename",
      type: :string,
      description: "Introspection: The name of the object type currently being queried.",
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

end
