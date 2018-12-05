defmodule Absinthe.Phase.Schema.Validation.QueryTypeMustBeObject do
  use Absinthe.Phase
  alias Absinthe.Blueprint

  def run(bp, _) do
    bp = Blueprint.prewalk(bp, &validate_schemas/1)
    {:ok, bp}
  end

  defp validate_schemas(%Blueprint.Schema.SchemaDefinition{} = schema) do
    case Enum.find(
           schema.type_definitions,
           &match?(%Blueprint.Schema.ObjectTypeDefinition{identifier: :query}, &1)
         ) do
      nil ->
        schema |> put_error(error(schema))

      _ ->
        schema
    end
  end

  defp validate_schemas(node), do: node

  defp error(schema) do
    %Absinthe.Phase.Error{
      message: explanation(nil),
      locations: [schema.__reference__.location],
      phase: __MODULE__
    }
  end

  @moduledoc false

  @description """

  # Example
  defmodule MyApp.Schema do
    use Absinthe.Schema

    query do
      # Fields go here
    end
  end

  --------------------------------------
  From the graqhql schema specification

  A GraphQL schema includes types, indicating where query and mutation
  operations start. This provides the initial entry points into the type system.
  The query type must always be provided, and is an Object base type. The
  mutation type is optional; if it is null, that means the system does not
  support mutations. If it is provided, it must be an object base type.

  Reference: https://facebook.github.io/graphql/#sec-Initial-types
  """

  def explanation(_value) do
    """
    The root query type must be implemented and be of type Object

    #{@description}
    """
  end
end
