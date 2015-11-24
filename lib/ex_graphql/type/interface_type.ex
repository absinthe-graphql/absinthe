defmodule ExGraphQL.Type.InterfaceType do
  @type t :: %{name: binary, description: binary, fields: map, resolve_type: ((any, ExGraphQL.Type.ResolveInfo.t) -> ExGraphQL.Type.ObjectType.t), types: [ExGraphQL.Type.t]}
  defstruct name: nil, description: nil, fields: nil, resolve_type: nil, types: []

  def resolve_type(%{resolve_type: nil} = interface, candidate) do
    default_resolver(interface, candidate)
  end
  def resolve_type(%{resolve_type: resolver} = interface, candidate) do
    resolver.(interface, candidate)
  end

  defp default_resolver(%{types: types}, %{name: name}) do
    types
    |> Enum.find(&(&1.name == name))
  end
  defp default_resolver(_, _) do
    nil
  end

end
