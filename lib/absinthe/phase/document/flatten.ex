defmodule Absinthe.Phase.Document.Flatten do
  @moduledoc """
  Flatten inline fragment contents and named fragments (via fragment spreads)
  from operation and field selections into their fields list. Resulting fields
  are tagged with the fragment type conditions.

  Note that no field merging or schema-based validation occurs in this phase.
  """

  use Absinthe.Phase
  alias Absinthe.Blueprint

  @spec run(Blueprint.t, Keyword.t) :: {:ok, Blueprint.t}
  def run(input, _) do
    # TODO
    {:ok, input}
  end

end
