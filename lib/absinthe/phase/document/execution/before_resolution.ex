defmodule Absinthe.Phase.Document.Execution.BeforeResolution do

  @moduledoc false

  use Absinthe.Phase

  alias Absinthe.{Blueprint}

  @spec run(Blueprint.t, Keyword.t) :: Phase.result_t
  def run(%{resolution: resolution} = bp_root, _opts \\ []) do
    acc = Enum.reduce(bp_root.schema.plugins(), resolution.acc, fn plugin, acc ->
      plugin.before_resolution(acc)
    end)

    {:ok, %{bp_root | resolution: %{resolution | acc: acc}}}
  end
end
