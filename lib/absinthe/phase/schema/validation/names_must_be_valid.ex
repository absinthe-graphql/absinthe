defmodule Absinthe.Phase.Schema.Validation.NamesMustBeValid do
  @moduledoc false

  use Absinthe.Phase
  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Schema

  @valid_name_regex ~r/[_A-Za-z][_0-9A-Za-z]*/

  def run(bp, _) do
    bp = Blueprint.prewalk(bp, &validate_names/1)
    {:ok, bp}
  end

  defp validate_names(%{name: nil} = entity) do
    entity
  end

  defp validate_names(%struct{name: name} = entity) do
    if valid_name?(name) do
      entity
    else
      kind = struct_to_kind(struct)
      detail = %{artifact: "#{kind} name", value: entity.name}
      entity |> put_error(error(entity, detail))
    end
  end

  defp validate_names(entity) do
    entity
  end

  defp valid_name?(name) do
    [match] = Regex.run(@valid_name_regex, name)
    match == name
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
  defp struct_to_kind(Schema.ScalarTypeDefinition), do: "scalar"
  defp struct_to_kind(Schema.ObjectTypeDefinition), do: "object"
  defp struct_to_kind(Schema.InputObjectTypeDefinition), do: "input object"
  defp struct_to_kind(_), do: "type"

  @description """
  Name does not match possible #{inspect(@valid_name_regex)} regex.

  > Names in GraphQL are limited to this ASCII subset of possible characters to
  > support interoperation with as many other systems as possible.

  Reference: https://graphql.github.io/graphql-spec/June2018/#sec-Names

  """

  def explanation(%{artifact: artifact, value: value}) do
    artifact_name = String.capitalize(artifact)

    """
    #{artifact_name} #{inspect(value)} has invalid characters.

    #{@description}
    """
  end
end
