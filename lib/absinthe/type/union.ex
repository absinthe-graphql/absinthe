defmodule Absinthe.Type.Union do

  # TODO: Unions are not yet fully supported
  @moduledoc false

  use Absinthe.Introspection.Kind

  alias Absinthe.Type

  @typedoc false
  @type t :: %{name: binary,
               description: binary,
               types: [Absinthe.Type.t],
               resolve_type: ((any, Absinthe.Execution.t) -> atom | nil), reference: Type.Reference.t}

  defstruct name: nil, description: nil, resolve_type: nil, types: [], reference: nil

  @doc false
  def member?(%{types: types}, type) do
    types
    |> Enum.member?(type)
  end

  @spec resolve_type(t, any, Execution.t) :: Type.t | nil
  def resolve_type(%{resolve_type: nil, types: types}, obj, _exe) do
    Enum.find(types, fn
      %{is_type_of: nil} ->
        false
      type ->
        type.is_type_of.(obj)
    end)
  end
  def resolve_type(%{resolve_type: resolver}, obj, %{schema: schema} = exe) do
    case resolver.(obj, exe) do
      nil ->
        nil
      ident when is_atom(ident) ->
        schema.types[ident]
    end
  end

end
