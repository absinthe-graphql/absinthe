defmodule Absinthe.Phase.Schema.Validation.ObjectMustDefineFields do
  @moduledoc false

  use Absinthe.Phase
  alias Absinthe.Blueprint

  def run(bp, _) do
    bp = Blueprint.prewalk(bp, &handle_schemas/1)
    {:ok, bp}
  end

  defp handle_schemas(%Blueprint.Schema.SchemaDefinition{} = schema) do
    schema = Blueprint.prewalk(schema, &validate_objects/1)
    {:halt, schema}
  end

  defp handle_schemas(obj) do
    obj
  end

  defp validate_objects(%Blueprint.Schema.TypeExtensionDefinition{} = node) do
    {:halt, node}
  end

  defp validate_objects(%struct{} = node)
       when struct in [
              Blueprint.Schema.ObjectTypeDefinition,
              Blueprint.Schema.InterfaceTypeDefinition,
              Blueprint.Schema.InputObjectTypeDefinition
            ] do
    if defines_fields?(node) do
      node
    else
      put_error(node, error(node))
    end
  end

  defp validate_objects(node) do
    node
  end

  defp defines_fields?(%{fields: []}) do
    false
  end

  defp defines_fields?(object) do
    !Enum.all?(object.fields, &introspection?(&1))
  end

  defp introspection?(%{name: "__" <> _}), do: true
  defp introspection?(_), do: false

  defp error(object) do
    %Absinthe.Phase.Error{
      message: explanation(object),
      locations: [object.__reference__.location],
      phase: __MODULE__
    }
  end

  def explanation(object) do
    kind = Absinthe.Blueprint.Schema.struct_to_kind(object)
    "The #{kind} type `#{object.identifier}` must define one or more fields."
  end
end
