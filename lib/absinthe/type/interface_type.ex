defmodule Absinthe.Type.InterfaceType do

  # TODO: Interfaces are not yet fully supported
  @moduledoc false

  alias Absinthe.Type

  @type t :: %{name: binary, description: binary, fields: map, resolve_type: ((any, Absinthe.Type.ResolveInfo.t) -> Absinthe.Type.ObjectType.t), types: [Absinthe.Type.t], reference: Type.Reference.t}
  defstruct name: nil, description: nil, fields: nil, resolve_type: nil, types: [], reference: nil

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
