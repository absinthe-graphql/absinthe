defmodule Absinthe.Phase.Schema.Validation.TypeNamesAreReserved do
  @moduledoc false

  use Absinthe.Phase
  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Schema

  def run(bp, _) do
    bp = Blueprint.prewalk(bp, &validate_reserved/1)
    {:ok, bp}
  end

  defp validate_reserved(%struct{name: "__" <> _} = entity) do
    if Absinthe.Type.built_in_module?(entity.__reference__.module) do
      entity
    else
      kind = struct_to_kind(struct)

      detail = %{artifact: "#{kind} name", value: entity.name}

      entity |> put_error(error(entity, detail))
    end
  end

  defp validate_reserved(entity) do
    entity
  end

  defp error(object, data) do
    %Absinthe.Phase.Error{
      message: explanation(data),
      locations: [object.__reference__.location],
      phase: __MODULE__,
      extra: data
    }
  end

  defp struct_to_kind(Schema.InputValueDefinition), do: "argument"
  defp struct_to_kind(Schema.FieldDefinition), do: "field"
  defp struct_to_kind(Schema.DirectiveDefinition), do: "directive"
  defp struct_to_kind(_), do: "type"

  @description """
  Type system artifacts must not begin with two leading underscores.

  > GraphQL type system authors must not define any types, fields, arguments,
  > or any other type system artifact with two leading underscores.

  Reference: https://github.com/facebook/graphql/blob/master/spec/Section%204%20--%20Introspection.md#naming-conventions

  """

  def explanation(%{artifact: artifact, value: value}) do
    artifact_name = String.capitalize(artifact)

    """
    #{artifact_name} #{inspect(value)} starts with two leading underscores.

    #{@description}
    """
  end
end
