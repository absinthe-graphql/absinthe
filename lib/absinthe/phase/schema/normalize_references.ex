defmodule Absinthe.Phase.Schema.NormalizeReferences do
  @moduledoc false

  # TODO: this is a temporary hack to be removed before 1.5 final.

  use Absinthe.Phase
  alias Absinthe.Blueprint

  def run(blueprint, _opts) do
    blueprint = Blueprint.prewalk(blueprint, &normalize_references/1)
    {:ok, blueprint}
  end

  def normalize_references(%Blueprint.TypeReference.Name{name: "Int"}) do
    :integer
  end

  def normalize_references(%Blueprint.TypeReference.Name{name: name}) do
    name |> Macro.underscore() |> String.to_atom()
  end

  def normalize_references(node), do: node
end
