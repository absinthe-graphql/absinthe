defmodule Absinthe.Schema.Rule.QueryTypeMustBeObject do
  use Absinthe.Schema.Rule

  alias Absinthe.Schema
  require IEx

  @moduledoc false

  @description """

  #Example
  defmodule MyApp.Schema do
    use Absinthe.Schema

    query do
      #Fields go here
    end
  end

  --------------------------------------
  From the graqhql schema specifiation

  A GraphQL schema includes types, indicating where query and mutation
  operations start. This provides the initial entry points into the type system.
  The query type must always be provided, and is an Object base type. The
  mutation type is optional; if it is null, that means the system does not
  support mutations. If it is provided, it must be an object base type.

  Reference: https://facebook.github.io/graphql/#sec-Initial-types
  """

  def explanation(_value) do
    """
    The root query type must be implemented and be a of type Object

    #{@description}
    """
  end

  def check(schema) do
    case Schema.lookup_type(schema, :query) do
      %Absinthe.Type.Object{} ->
        []

      # Real error message
      _ ->
        [report(%{file: schema, line: 0}, %{})]
    end
  end
end
