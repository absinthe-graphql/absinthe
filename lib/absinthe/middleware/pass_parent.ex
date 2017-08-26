defmodule Absinthe.Middleware.PassParent do
  @moduledoc """
  This is the default middleware.
  """

  @behaviour Absinthe.Middleware

  def call(%{source: parent} = res, _) do
    %{res | state: :resolved, value: parent}
  end
end
