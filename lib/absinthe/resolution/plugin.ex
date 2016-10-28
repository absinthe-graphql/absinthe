defmodule Absinthe.Resolution.Plugin do

  # TODO: Add behaviour callbacks

  @doc """
  The default list of resolution plugins
  """
  def defaults do
    [Absinthe.Resolution.Plugin.Async]
  end

  @doc false
  def additional_phases(plugins, resolution) do
    resolution_acc = resolution.acc
    Enum.reduce(plugins, [], fn plugin, pipeline ->
      plugin.add_phases(pipeline, resolution_acc)
    end)
    |> List.flatten
    |> Enum.dedup
  end
end
