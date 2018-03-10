defmodule Absinthe.Schema.Rule.TypeNamesAreUnique do
  use Absinthe.Schema.Rule

  @moduledoc false

  @description """
  References to types must be unique.

  > All types within a GraphQL schema must have unique names. No two provided
  > types may have the same name. No provided type may have a name which
  > conflicts with any built in types (including Scalar and Introspection
  > types).

  Reference: https://github.com/facebook/graphql/blob/master/spec/Section%203%20--%20Type%20System.md#type-system
  """

  def explanation(%{data: %{artifact: artifact, value: name}}) do
    """
    #{artifact} #{inspect(name)} is not unique.

    #{@description}
    """
  end

  # This rule is only used for its explanation. Error details are added during
  # compilation.
  def check(_), do: []
end
