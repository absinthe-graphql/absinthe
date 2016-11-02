defmodule Absinthe.Phase.Blueprint do
  use Absinthe.Phase

  @moduledoc false

  alias Absinthe.Blueprint

  @spec run(any, Keyword.t) :: {:ok, Blueprint.t}
  def run(input, _options \\ []) do
    doc = input # The doc is also the input
    {:ok, Blueprint.Draft.convert(input, doc)}
  end

end
