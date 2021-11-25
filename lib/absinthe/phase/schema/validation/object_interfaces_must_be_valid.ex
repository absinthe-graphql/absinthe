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
      |> Map.new(&{&1.identifier, &1})

    schema = Blueprint.prewalk(schema, &validate_objects(&1, ifaces))
    {:halt, schema}
  end

  defp handle_schemas(obj) do
    obj
  end

  defp validate_objects(%struct{} = object, all_interfaces)
       when struct in [
              Blueprint.Schema.ObjectTypeDefinition,
              Blueprint.Schema.InterfaceTypeDefinition
            ] do
    check_transitive_interfaces(object, object.interfaces, all_interfaces, nil, [])
  end

  defp validate_objects(type, _) do
    type
  end

  # check that the object declares it implements all interfaces up the
  # hierarchy chain as per spec https://github.com/graphql/graphql-spec/blame/October2021/spec/Section%203%20--%20Type%20System.md#L1158-L1161
  defp check_transitive_interfaces(
         object,
         [object_interface | tail],
         all_interfaces,
         implemented_by,
         visited
       ) do
    current_interface = all_interfaces[object_interface]

    if current_interface && current_interface.identifier in object.interfaces do
      case current_interface do
        %{interfaces: interfaces} = interface ->
          # to prevent walking in cycles we need to filter out visited interfaces
          interfaces = Enum.filter(interfaces, &(&1 not in visited))

          check_transitive_interfaces(object, tail ++ interfaces, all_interfaces, interface, [
            object_interface | visited
          ])

        _ ->
          check_transitive_interfaces(object, tail, all_interfaces, implemented_by, [
            object_interface | visited
          ])
      end
    else
      detail = %{
        object: object.identifier,
        interface: object_interface,
        implemented_by: implemented_by
      }

      object |> put_error(error(object, detail))
    end
  end

  defp check_transitive_interfaces(object, [], _, _, _) do
    object
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

  def explanation(%{object: obj, interface: interface, implemented_by: nil}) do
    """
    Type "#{obj}" must implement interface type "#{interface}"

    #{@description}
    """
  end

  def explanation(%{object: obj, interface: interface, implemented_by: implemented}) do
    """
    Type "#{obj}" must implement interface type "#{interface}" because it is implemented by "#{
      implemented.identifier
    }".

    #{@description}
    """
  end
end
