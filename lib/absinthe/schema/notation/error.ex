defmodule Absinthe.Schema.Notation.Error do
  @moduledoc """
  Exception raised when a schema is invalid
  """
  defexception message: "Invalid notation schema"

  def exception(message) do
    %__MODULE__{message: message}
  end
end
