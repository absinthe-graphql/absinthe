defmodule Absinthe.Phase.Blueprint do
  use Absinthe.Phase

  @moduledoc false

  alias Absinthe.Blueprint

  @spec run(any, Keyword.t()) :: {:ok, Blueprint.t()}
  def run(blueprint, _options \\ []) do
    input = blueprint.input
    blueprint = Blueprint.Draft.convert(input, blueprint)

    {:ok, blueprint}
  end
end
