defmodule Absinthe.Phase.Blueprint do
  use Absinthe.Phase

  @moduledoc false

  alias Absinthe.Blueprint

  @spec run(any, Keyword.t) :: {:ok, Blueprint.t}
  def run(blueprint, _options \\ []) do
    input = blueprint.input # The doc is also the input
    {:ok, Blueprint.Draft.convert(input, blueprint)}
  end

end
