defmodule Absinthe.Blueprint.TypeReference do
  @moduledoc false

  alias __MODULE__

  @type t ::
          TypeReference.List.t()
          | TypeReference.Name.t()
          | TypeReference.NonNull.t()

  @wrappers [TypeReference.List, TypeReference.NonNull]

  @doc """
  Unwrap a type reference from surrounding NonNull/List type information.
  """
  @spec unwrap(t) :: t
  def unwrap(%TypeReference.Name{} = value) do
    value
  end

  def unwrap(%struct{of_type: inner}) when struct in @wrappers do
    unwrap(inner)
  end
end
