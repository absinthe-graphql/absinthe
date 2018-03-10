defmodule Absinthe.Schema.Rule.ObjectInterfacesMustBeValid do
  use Absinthe.Schema.Rule

  alias Absinthe.Schema
  alias Absinthe.Type

  @moduledoc false
  @description """
  Only interfaces may be present in an Object's interface list.

  Reference: https://github.com/facebook/graphql/blob/master/spec/Section%203%20--%20Type%20System.md#interfaces
  """

  def explanation(%{data: %{object: obj, interface: interface}}) do
    """
    Type "#{obj}" cannot implement non-interface type "#{interface}"

    #{@description}
    """
  end

  def check(schema) do
    Schema.types(schema)
    |> Enum.flat_map(&check_type(schema, &1))
  end

  defp check_type(schema, %{interfaces: ifaces} = type) do
    ifaces
    |> Enum.map(&Schema.lookup_type(schema, &1))
    |> Enum.reduce([], fn
      nil, _ ->
        raise "No type found in #{inspect(ifaces)}"

      %Type.Interface{}, acc ->
        acc

      iface_type, acc ->
        [
          report(type.__reference__.location, %{object: type.name, interface: iface_type.name})
          | acc
        ]
    end)
  end

  defp check_type(_, _) do
    []
  end
end
