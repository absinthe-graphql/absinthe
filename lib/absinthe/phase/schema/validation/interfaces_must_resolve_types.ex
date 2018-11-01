defmodule Absinthe.Phase.Schema.Validation.InterfacesMustResolveTypes do
  @moduledoc false

  use Absinthe.Phase
  alias Absinthe.Blueprint

  def run(bp, _) do
    bp = Blueprint.prewalk(bp, &handle_schemas/1)
    {:ok, bp}
  end

  defp handle_schemas(%Blueprint.Schema.SchemaDefinition{} = schema) do
    implementors =
      schema.type_definitions
      |> Enum.filter(&match?(%Blueprint.Schema.ObjectTypeDefinition{}, &1))
      |> Enum.flat_map(fn obj ->
        for iface <- obj.interfaces do
          {iface, obj}
        end
      end)
      |> Enum.group_by(fn {iface, _obj} -> iface end, fn {_iface, obj} -> obj end)

    schema = Blueprint.prewalk(schema, &validate_interface(&1, implementors))
    {:halt, schema}
  end

  defp handle_schemas(obj) do
    obj
  end

  defp validate_interface(%Blueprint.Schema.InterfaceTypeDefinition{} = iface, implementors) do
    resolve_type = Absinthe.Type.function(iface, :resolve_type)

    if(resolve_type || all_objects_is_type_of?(iface, implementors)) do
      iface
    else
      iface |> put_error(error(iface))
    end
  end

  defp validate_interface(type, _) do
    type
  end

  defp all_objects_is_type_of?(iface, implementors) do
    implementors
    |> Map.get(iface.identifier, [])
    |> Enum.all?(&Absinthe.Type.function(&1, :is_type_of))
  end

  defp error(interface) do
    %Absinthe.Phase.Error{
      message: explanation(interface.identifier),
      locations: [interface.__reference__.location],
      phase: __MODULE__,
      extra: interface.identifier
    }
  end

  @description """
  An interface must be able to resolve the implementing types of results.

  > The interface type should have some way of determining which object a given
  > result corresponds to.

  Reference: https://github.com/facebook/graphql/blob/master/spec/Section%203%20--%20Type%20System.md#interfaces
  """

  def explanation(interface) do
    """
    Interface type "#{interface}" either:
    * Does not have a `resolve_type` function.
    * Is missing a `is_type_of` function on all implementing types.

    #{@description}
    """
  end
end
