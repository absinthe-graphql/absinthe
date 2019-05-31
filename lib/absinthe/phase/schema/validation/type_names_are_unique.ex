defmodule Absinthe.Phase.Schema.Validation.TypeNamesAreUnique do
  use Absinthe.Phase
  alias Absinthe.Blueprint

  def run(bp, _) do
    bp =
      bp
      |> Blueprint.prewalk(&handle_schemas(&1, :identifier))
      |> Blueprint.prewalk(&handle_schemas(&1, :name))

    {:ok, bp}
  end

  defp handle_schemas(%Blueprint.Schema.SchemaDefinition{} = schema, key) do
    if Enum.any?(schema.type_definitions, fn
         %Blueprint.Schema.SchemaDefinition{} ->
           true

         _ ->
           false
       end) do
      raise "SchemaDefinition Inside Schema Definition"
    end

    types = Enum.group_by(schema.type_definitions, &Map.fetch!(&1, key))
    directives = Enum.group_by(schema.directive_definitions, &Map.fetch!(&1, key))

    types = Map.merge(types, directives)

    schema = Blueprint.prewalk(schema, &validate_types(&1, types, key))
    {:halt, schema}
  end

  defp handle_schemas(obj, _) do
    obj
  end

  @types [
    Blueprint.Schema.DirectiveDefinition,
    Blueprint.Schema.EnumTypeDefinition,
    Blueprint.Schema.InputObjectTypeDefinition,
    Blueprint.Schema.InterfaceTypeDefinition,
    Blueprint.Schema.ObjectTypeDefinition,
    Blueprint.Schema.ScalarTypeDefinition,
    Blueprint.Schema.UnionTypeDefinition
  ]
  defp validate_types(%type{} = object, types, key) when type in @types do
    ident = Map.fetch!(object, key)

    case Map.fetch!(types, ident) do
      [_] ->
        object

      others ->
        detail = %{
          value: ident,
          artifact:
            case key do
              :identifier -> "Absinthe type identifier"
              :name -> "Type name"
            end
        }

        object |> put_error(error(detail, others))
    end
  end

  defp validate_types(type, _, _) do
    type
  end

  defp error(data, types) do
    %Absinthe.Phase.Error{
      message: explanation(data),
      locations: types |> Enum.map(& &1.__reference__.location),
      phase: __MODULE__,
      extra: data
    }
  end

  @moduledoc false

  @description """
  References to types must be unique.

  > All types within a GraphQL schema must have unique names. No two provided
  > types may have the same name. No provided type may have a name which
  > conflicts with any built in types (including Scalar and Introspection
  > types).

  Reference: https://github.com/facebook/graphql/blob/master/spec/Section%203%20--%20Type%20System.md#type-system
  """

  def explanation(%{artifact: artifact, value: name}) do
    """
    #{artifact} #{inspect(name)} is not unique.

    #{@description}
    """
  end

  # This rule is only used for its explanation. Error details are added during
  # compilation.
  def check(_), do: []
end
