defmodule Absinthe.Blueprint.SourceLocation do
  @moduledoc false

  @enforce_keys [:line, :column]
  defstruct [
    :line,
    :column
  ]

  @type t :: %__MODULE__{
          line: pos_integer,
          column: pos_integer
        }

  @doc """
  Generate a `SourceLocation.t()` given a location
  """
  @spec at(loc :: Absinthe.Language.loc_t()) :: t
  def at(loc) do
    %__MODULE__{line: loc.line, column: loc.column}
  end

  @doc """
  Generate a `SourceLocation.t()` given line and column numbers
  """
  @spec at(line :: pos_integer, column :: pos_integer) :: t
  def at(line, column) do
    %__MODULE__{line: line, column: column}
  end
end
