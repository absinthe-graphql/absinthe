defmodule Absinthe.Phase.Schema.Validation.UniqueFieldNames do
  @moduledoc false

  @behaviour Absinthe.Phase
  alias Absinthe.Blueprint

  def run(bp, _) do
    bp =
      bp
      |> Blueprint.prewalk(&handle_schemas(&1, :name))

    {:ok, bp}
  end

  defp handle_schemas(%Blueprint.Schema.SchemaDefinition{} = schema, key) do
    schema = Blueprint.prewalk(schema, &validate_types(&1, key))
    {:halt, schema}
  end

  defp handle_schemas(obj, _) do
    obj
  end

  defp validate_types(%type{} = object, key)
       when type in [
              Blueprint.Schema.InputObjectTypeDefinition,
              Blueprint.Schema.InterfaceTypeDefinition,
              Blueprint.Schema.ObjectTypeDefinition
            ] do
    fields =
      for field <- object.fields do
        name_counts = Enum.frequencies_by(object.fields, &Map.get(&1, key))

        if duplicate?(name_counts, field, key) do
          Absinthe.Phase.put_error(field, error(field, object))
        else
          field
        end
      end

    %{object | fields: fields}
  end

  defp validate_types(type, _) do
    type
  end

  defp duplicate?(name_counts, field, key) do
    field_identifier = Map.get(field, key)
    Map.get(name_counts, field_identifier, 0) > 1
  end

  defp error(field, object) do
    %Absinthe.Phase.Error{
      message: explanation(field, object),
      locations: [field.__reference__.location],
      phase: __MODULE__,
      extra: field
    }
  end

  def explanation(field, object) do
    """
    The field #{inspect(field.name)} is not unique in type #{inspect(object.name)}.

    The field must have a unique name within that Object type; no two fields may share the same name.
    """
  end
end
