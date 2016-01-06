defmodule Absinthe.Type.Union do

  # TODO: Unions are not yet fully supported
  @moduledoc false

  use Absinthe.Introspection.Kind

  alias Absinthe.Type

  @typedoc false
  @type t :: %{name: binary,
               description: binary,
               resolve_type: ((t, any) -> Absinthe.Type.Object.t),
               types: [Absinthe.Type.t],
               reference: Type.Reference.t}

  defstruct name: nil, description: nil, resolve_type: nil, types: [], reference: nil

  @doc false
  def member?(%{types: types}, type) do
    types
    |> Enum.member?(type)
  end

  @doc false
  def resolve_type(%{resolve_type: nil} = union, candidate) do
    default_resolver(union, candidate)
  end
  def resolve_type(%{resolve_type: resolver} = union, candidate) do
    resolver.(union, candidate)
  end

  @doc false
  defp default_resolver(%{types: types}, %{name: name}) do
    types
    |> Enum.find(&(&1.name == name))
  end
  defp default_resolver(_, _) do
    nil
  end

end
