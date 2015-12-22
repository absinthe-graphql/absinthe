defmodule Absinthe.Type.Union do

  @type t :: %{name: binary,
               description: binary,
               resolve_type: ((t, any) -> Absinthe.Type.ObjectType.t),
              types: [Absinthe.Type.t]}

  defstruct name: nil, description: nil, resolve_type: nil, types: []

  def member?(%{types: types}, type) do
    types
    |> Enum.member?(type)
  end

  def resolve_type(%{resolve_type: nil} = union, candidate) do
    default_resolver(union, candidate)
  end
  def resolve_type(%{resolve_type: resolver} = union, candidate) do
    resolver.(union, candidate)
  end

  defp default_resolver(%{types: types}, %{name: name}) do
    types
    |> Enum.find(&(&1.name == name))
  end
  defp default_resolver(_, _) do
    nil
  end

end
