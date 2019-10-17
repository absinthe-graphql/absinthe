defmodule Absinthe.Phase.Schema.Validation.ObjectInterfacesMustBeValid do
  @moduledoc false

  use Absinthe.Phase
  alias Absinthe.Blueprint

  def run(bp, _) do
    bp = Blueprint.prewalk(bp, &handle_schemas/1)
    {:ok, bp}
  end

  defp handle_schemas(%Blueprint.Schema.SchemaDefinition{} = schema) do
    ifaces =
      schema.type_definitions
      |> Enum.filter(&match?(%Blueprint.Schema.InterfaceTypeDefinition{}, &1))
      |> Enum.map(& &1.identifier)
      |> MapSet.new()

    schema = Blueprint.prewalk(schema, &validate_objects(&1, ifaces))
    {:halt, schema}
  end

  defp handle_schemas(obj) do
    obj
  end

  defp validate_objects(%Blueprint.Schema.ObjectTypeDefinition{} = object, ifaces) do
    Enum.reduce(object.interfaces, object, fn iface, object ->
      if iface in ifaces do
        object
      else
        detail = %{
          object: object.identifier,
          interface: iface
        }

        object |> put_error(error(object, detail))
      end
    end)
  end

  defp validate_objects(type, _) do
    type
  end

  defp error(object, data) do
    %Absinthe.Phase.Error{
      message: explanation(data),
      locations: [object.__reference__.location],
      phase: __MODULE__,
      extra: data
    }
  end

  @description """
  Only interfaces may be present in an Object's interface list.

  Reference: https://github.com/facebook/graphql/blob/master/spec/Section%203%20--%20Type%20System.md#interfaces
  """

  def explanation(%{object: obj, interface: interface}) do
    """
    Type "#{obj}" cannot implement non-interface type "#{interface}"

    #{@description}
    """
  end
end
