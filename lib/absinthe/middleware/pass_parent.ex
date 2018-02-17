defmodule Absinthe.Middleware.PassParent do
  @moduledoc """
  Middleware that just passes the parent down to the children.

  This is the default resolver for subscription fields.
  """

  @behaviour Absinthe.Middleware

  def call(%{source: parent} = res, _) do
    %{res | state: :resolved, value: parent}
  end
end
