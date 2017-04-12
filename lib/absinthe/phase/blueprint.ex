defmodule Absinthe.Phase.Blueprint do
  use Absinthe.Phase

  @moduledoc false

  alias Absinthe.Blueprint

  @spec run(any, Keyword.t) :: {:ok, Blueprint.t}
  def run(input, options \\ []) do
    doc = input # The doc is also the input
    blueprint = Blueprint.Draft.convert(input, doc)

    context = Map.merge(blueprint.resolution.context, Keyword.get(options, :context, %{}))
    blueprint = put_in(blueprint.resolution.context, context)

    root_value = Map.merge(blueprint.resolution.root_value, Keyword.get(options, :root_value, %{}))
    blueprint = put_in(blueprint.resolution.root_value, root_value)

    {:ok, blueprint}
  end

end
