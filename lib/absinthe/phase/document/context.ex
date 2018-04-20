defmodule Absinthe.Phase.Document.Context do
  @moduledoc "Pass on context and root value to document."

  use Absinthe.Phase
  alias Absinthe.Blueprint

  @spec run(Blueprint.t(), Keyword.t()) :: {:ok, Blueprint.t()}
  def run(blueprint, options \\ []) do
    context = Map.merge(blueprint.execution.context, options[:context] || %{})
    blueprint = put_in(blueprint.execution.context, context)

    root_value = Map.merge(blueprint.execution.root_value, options[:root_value] || %{})
    blueprint = put_in(blueprint.execution.root_value, root_value)

    {:ok, blueprint}
  end
end
