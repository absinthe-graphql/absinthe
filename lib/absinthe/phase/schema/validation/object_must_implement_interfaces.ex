defmodule Absinthe.Phase.Schema.Validation.ObjectMustImplementInterfaces do
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

    types =
      schema.type_definitions
      |> Map.new(&{&1.identifier, &1})

    schema = Blueprint.prewalk(schema, &validate_objects(&1, ifaces, types))
    {:halt, schema}
  end

  defp handle_schemas(obj) do
    obj
  end

  defp validate_objects(%Blueprint.Schema.ObjectTypeDefinition{} = object, ifaces, types) do
    Enum.reduce(object.interfaces, object, fn ident, object ->
      case Map.fetch(ifaces, ident) do
        {:ok, iface} -> validate_object(object, iface, types)
        _ -> object
      end
    end)
  end

  defp validate_objects(type, _, _) do
    type
  end

  def validate_object(object, iface, types) do
    case check_implements(iface, object, types) do
      :ok ->
        object

      {:error, invalid_fields} ->
        detail = %{
          object: object.identifier,
          interface: iface.identifier,
          fields: invalid_fields
        }

        object |> put_error(error(object, detail))
    end
  end

  defp error(object, data) do
    %Absinthe.Phase.Error{
      message: explanation(data),
      locations: [object.__reference__.location],
      phase: __MODULE__,
      extra: data
    }
  end

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

  def explanation(%{object: obj, interface: interface, fields: fields}) do
    """
    Type "#{obj}" does not fully implement interface type "#{interface}" \
    for fields #{inspect(fields)}

    #{@description}
    """
  end

  def check_implements(interface, type, types) do
    check_covariant(interface, type, nil, types)
  end

  defp check_covariant(
         %Blueprint.Schema.InterfaceTypeDefinition{fields: ifields},
         %{fields: type_fields},
         _field_ident,
         types
       ) do
    Enum.reduce(ifields, [], fn %{identifier: ifield_ident} = ifield, invalid_fields ->
      case Enum.find(type_fields, &(&1.identifier == ifield_ident)) do
        nil ->
          [ifield_ident | invalid_fields]

        field ->
          case check_covariant(ifield.type, field.type, ifield_ident, types) do
            :ok ->
              invalid_fields

            {:error, invalid_field} ->
              [invalid_field | invalid_fields]
          end
      end
    end)
    |> case do
      [] ->
        :ok

      invalid_fields ->
        {:error, invalid_fields}
    end
  end

  defp check_covariant(
         %Blueprint.Schema.InterfaceTypeDefinition{identifier: interface_ident},
         interface_ident,
         _field_ident,
         _types
       ) do
    :ok
  end

  defp check_covariant(
         %Blueprint.Schema.InterfaceTypeDefinition{identifier: interface_ident},
         field_type,
         field_ident,
         types
       ) do
    %{interfaces: field_type_interfaces} = Map.get(types, field_type)
    (interface_ident in field_type_interfaces && :ok) || {:error, field_ident}
  end

  defp check_covariant(
         %wrapper{of_type: inner_type1},
         %wrapper{of_type: inner_type2},
         field_ident,
         types
       ) do
    check_covariant(inner_type1, inner_type2, field_ident, types)
  end

  defp check_covariant(%{identifier: identifier}, %{identifier: identifier}, _field_ident, _types) do
    :ok
  end

  defp check_covariant(
         %Blueprint.TypeReference.Name{name: name},
         %Blueprint.TypeReference.Name{name: name},
         _field_ident,
         _types
       ) do
    :ok
  end

  defp check_covariant(nil, _, field_ident, _), do: {:error, field_ident}
  defp check_covariant(_, nil, field_ident, _), do: {:error, field_ident}

  defp check_covariant(itype, type, field_ident, types) when is_atom(itype) do
    itype = Map.get(types, itype)
    check_covariant(itype, type, field_ident, types)
  end

  defp check_covariant(itype, type, field_ident, types) when is_atom(type) do
    type = Map.get(types, type)
    check_covariant(itype, type, field_ident, types)
  end

  defp check_covariant(_, _, field_ident, _types) do
    {:error, field_ident}
  end
end
