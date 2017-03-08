defmodule Absinthe.Phase.Document.Execution.AfterResolution do

  @moduledoc false

  use Absinthe.Phase

  alias Absinthe.{Blueprint}

  @spec run(Blueprint.t, Keyword.t) :: Phase.result_t
  def run(%{resolution: resolution} = bp_root, _opts \\ []) do
    acc = Enum.reduce(bp_root.schema.plugins, resolution.acc, fn plugin, acc ->
      plugin.after_resolution(acc)
    end)

    blueprint = %{bp_root | resolution: %{resolution | acc: acc}}

    bp_root.schema.plugins
    |> Absinthe.Middleware.pipeline(acc)
    |> case do
      [] ->
        {:ok, blueprint}
      phases ->
        {:insert, blueprint, phases}
    end
  end
end
