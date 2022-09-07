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

  A schema defines the initial root operation type for each kind of operation
  it supports: query, mutation, and subscription; this determines the place in
  the type system where those operations begin.

  The query root operation type must be provided and must be an Object type.

  The mutation root operation type is optional; if it is not provided, the service
  does not support mutations. If it is provided, it must be an Object type.

  Reference: https://spec.graphql.org/October2021/#sec-Root-Operation-Types
  """

  def explanation(_value) do
    """
    The root query type must be implemented and be of type Object

    #{@description}
    """
  end
end
