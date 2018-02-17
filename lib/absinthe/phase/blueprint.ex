defmodule Absinthe.Phase.Blueprint do
  use Absinthe.Phase

  @moduledoc false

  alias Absinthe.Blueprint

  @spec run(any, Keyword.t) :: {:ok, Blueprint.t}
  def run(blueprint, options \\ []) do
    input = blueprint.input
    blueprint = Blueprint.Draft.convert(input, blueprint)

    context = Map.merge(blueprint.execution.context, options[:context] || %{})
    blueprint = put_in(blueprint.execution.context, context)

    root_value = Map.merge(blueprint.execution.root_value, options[:root_value] || %{})
    blueprint = put_in(blueprint.execution.root_value, root_value)

    {:ok, blueprint}
  end

end
