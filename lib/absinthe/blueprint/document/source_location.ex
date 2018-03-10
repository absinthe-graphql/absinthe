defmodule Absinthe.Blueprint.Document.SourceLocation do
  @moduledoc false

  @enforce_keys [:line]
  defstruct line: nil,
            column: nil

  @type t :: %__MODULE__{
          line: integer,
          column: nil | integer
        }

  @doc """
  Easily generate a SourceLocation.t give a line and optional column.
  """
  @spec at(integer) :: t
  def at(line) do
    %__MODULE__{line: line}
  end

  @spec at(integer, integer) :: t
  def at(line, column) do
    %__MODULE__{line: line, column: column}
  end
end
