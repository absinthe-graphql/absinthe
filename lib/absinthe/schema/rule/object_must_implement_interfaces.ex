defmodule Absinthe.Schema.Rule.ObjectMustImplementInterfaces do
  use Absinthe.Schema.Rule

  alias Absinthe.Schema
  alias Absinthe.Type

  @moduledoc false

  @description """
  An object type must be a super-set of all interfaces it implements.

  * The object type must include a field of the same name for every field
    defined in an interface.
    * The object field must be of a type which is equal to or a sub-type of
      the interface field (covariant).
    * An object field type is a valid sub-type if it is equal to (the same
      type as) the interface field type.
    * An object field type is a valid sub-type if it is an Object type and the
      interface field type is either an Interface type or a Union type and the
      object field type is a possible type of the interface field type.
    * An object field type is a valid sub-type if it is a List type and the
      interface field type is also a List type and the list-item type of the
      object field type is a valid sub-type of the list-item type of the
      interface field type.
    * An object field type is a valid sub-type if it is a Non-Null variant of a
      valid sub-type of the interface field type.
  * The object field must include an argument of the same name for every
    argument defined in the interface field.
    * The object field argument must accept the same type (invariant) as the
      interface field argument.
  * The object field may include additional arguments not defined in the
    interface field, but any additional argument must not be required.

  Reference: https://github.com/facebook/graphql/blob/master/spec/Section%203%20--%20Type%20System.md#object-type-validation
  """

  def explanation(%{data: %{object: obj, interface: interface}}) do
    """
    Type "#{obj}" does not fully implement interface type "#{interface}"

    #{@description}
    """
  end

  def check(schema) do
    schema
    |> Schema.types()
    |> Enum.flat_map(&check_type(schema, &1))
  end

  defp check_type(schema, %{interfaces: ifaces} = type) do
    ifaces
    |> Enum.map(&Schema.lookup_type(schema, &1))
    |> Enum.reduce([], fn
      %Type.Interface{} = iface_type, acc ->
        if Type.Interface.implements?(iface_type, type, schema) do
          acc
        else
          [
            report(type.__reference__.location, %{object: type.name, interface: iface_type.name})
            | acc
          ]
        end

      _, _ ->
        # Handles by a different rule
        []
    end)
  end

  defp check_type(_, _) do
    []
  end
end
