defmodule Absinthe.Schema.Error do
  @moduledoc """
  Exception raised when a schema is invalid
  """
  defexception phase_errors: []

  def message(error) do
    details =
      error.phase_errors
      |> Enum.map(fn %{message: message, locations: locations} ->
        locations =
          locations
          |> Enum.map(fn
            %{line: line, file: file} -> "#{file}:#{line}"
            %{column: column, line: line} -> "Column #{column}, Line #{line}"
          end)
          |> Enum.sort()
          |> Enum.join("\n")

        message = String.trim(message)

        """
        ---------------------------------------
        ## Locations
        #{locations}

        #{message}
        """
      end)
      |> Enum.join()

    """
    Compilation failed:
    #{details}
    """
  end
end
