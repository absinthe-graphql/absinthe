defmodule Absinthe.Middleware.Default do
  @moduledoc """
  This is the default middlware. 
  """

  @behaviour Absinthe.Middleware

  def call(%{source: source} = res, field_name) do
    %{res | result: Map.get(source, field_name)}
  end
end
