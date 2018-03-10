defmodule Absinthe.Schema.Rule.InterfacesMustResolveTypes do
  use Absinthe.Schema.Rule

  alias Absinthe.Schema
  alias Absinthe.Type

  @moduledoc false

  @description """
  An interface must be able to resolve the implementing types of results.

  > The interface type should have some way of determining which object a given
  > result corresponds to.

  Reference: https://github.com/facebook/graphql/blob/master/spec/Section%203%20--%20Type%20System.md#interfaces
  """

  def explanation(%{data: interface}) do
    """
    Interface type "#{interface}" either:
    * Does not have a `resolve_type` function.
    * Is missing a `is_type_of` function on all implementing types.

    #{@description}
    """
  end

  def check(schema) do
    Schema.types(schema)
    |> Enum.flat_map(&check_type(schema, &1))
  end

  defp check_type(schema, %Type.Interface{} = type) do
    if Type.Interface.type_resolvable?(schema, type) do
      []
    else
      [report(type.__reference__.location, type.name)]
    end
  end

  defp check_type(_, _) do
    []
  end
end
