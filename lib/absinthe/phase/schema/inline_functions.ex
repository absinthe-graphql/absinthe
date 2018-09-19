defmodule Absinthe.Phase.Schema.InlineFunctions do
  @moduledoc false

  use Absinthe.Phase
  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Schema

  def run(blueprint, _opts) do
    blueprint = Blueprint.prewalk(blueprint, &inline_functions/1)
    {:ok, blueprint}
  end

  def inline_functions(%type{} = node) do
    type
    |> Schema.functions()
    |> Enum.reduce(node, &inline_function/2)
  end

  def inline_functions(node) do
    node
  end

  defp inline_function(attr, node) do
    function = Absinthe.Type.function(node, attr)

    if Absinthe.Utils.escapable?(function) do
      %{node | attr => function}
    else
      node
    end
  end
end
