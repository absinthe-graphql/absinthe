defmodule Absinthe.Phase.Blueprint do
  use Absinthe.Phase

  alias Absinthe.Blueprint

  @spec run(any) :: {:ok, Blueprint.t}
  def run(input) do
    doc = input # The doc is also the input
    {:ok, Blueprint.Draft.convert(input, doc)}
  end

end
