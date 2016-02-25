defmodule Absinthe.Schema.Notation.Error do
  @moduledoc """
  Exception raised when a schema is invalid
  """
  defexception message: "Invalid notation schema"

  def exception(kind) do
    %__MODULE__{message: "Invalid notation schema: #{detail kind}"}
  end

  defp detail(kind) do
    "#{kind} is not valid in this context"
  end

end
