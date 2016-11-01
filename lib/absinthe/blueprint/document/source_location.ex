defmodule Absinthe.Blueprint.Document.SourceLocation do

  @moduledoc false

  defstruct [
    line: nil,
    column: nil,
  ]

  @type t :: %__MODULE__{
    line: nil | integer,
    column: nil | integer,
  }

  @doc """
  Easily generate a SourceLocation.t give a line and optional column.
  """
  @spec at(integer) :: t
  @spec at(integer, integer) :: t
  def at(line, column \\ nil) do
    %__MODULE__{line: line, column: column}
  end

end
