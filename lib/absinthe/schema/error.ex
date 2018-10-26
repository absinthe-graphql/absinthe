defmodule Absinthe.Schema.Error do
  @moduledoc """
  Exception raised when a schema is invalid
  """
  defexception phase_errors: []

  def message(error) do
    details =
      error.phase_errors
      |> Enum.map(fn %{message: message, locations: [location]} ->
        "#{location.file}:#{location.line} - #{message}"
      end)
      |> Enum.join("\n")

    """
    Compilation failed:
    #{details}
    """
  end
end
