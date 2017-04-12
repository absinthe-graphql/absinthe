defmodule Absinthe.Phase.Blueprint do
  use Absinthe.Phase

  @moduledoc false

  alias Absinthe.Blueprint

  @spec run(any, Keyword.t) :: {:ok, Blueprint.t}
  def run(blueprint, options \\ []) do
    input = blueprint.input
    blueprint = Blueprint.Draft.convert(input, blueprint)

    context = Map.merge(blueprint.resolution.context, options[:context] || %{})
    blueprint = put_in(blueprint.resolution.context, context)

    root_value = Map.merge(blueprint.resolution.root_value, options[:root_value] || %{})
    blueprint = put_in(blueprint.resolution.root_value, root_value)

    {:ok, blueprint}
  end

end
