defmodule Absinthe.Resolution.Plugin do

  alias Absinthe.Blueprint.Document

  @typedoc """
  Any module that implements this behaviour
  """
  @type t :: atom

  @doc """
  Function called prior to the execution of a resolution phase.

  This allows plugins to setup any data in the resolution accumulator they may
  need.

  NOTE: This function is given the full accumulator. Namespacing is suggested to
  avoid conflicts.
  """
  @callback before_resolution(resolution_acc :: Document.Resolution.acc) :: Document.Resolution.acc

  @doc """
  Function called after the execution of a resolution phase.

  NOTE: This function is given the full accumulator. Namespacing is suggested to
  avoid conflicts.
  """
  @callback after_resolution(resolution_acc :: Document.Resolution.acc) :: Document.Resolution.acc

  @doc """
  Add any additional phases required by the plugin.

  Plugins may require additional resolution phases to be run. This function should
  use values set in the resolution accumulator
  whether or not additional phases are required.

  NOTE: This function is given the whole pipeline to be inserted after the current
  phase completes.
  """
  @callback pipeline(next_pipeline :: Absinthe.Pipeline.t, resolution_acc :: Map.t) :: Absinthe.Pipeline.t

  @doc """
  Called after a field invokes the plugin.

  Resolution functions invoke a function via:
  ```elixir
  {:plugin, PluginModule, plugin_data}
  ```

  The first argument to `init` is whatever plugin_data is. The second is the
  resolution accumulator.

  NOTE: This function is given the full accumulator. Namespacing is suggested to
  avoid conflicts.
  """
  @callback init(any, Document.Resolution.acc) :: {any :: Document.Resolution.acc}

  @doc """
  The default list of resolution plugins
  """
  def defaults do
    [Absinthe.Resolution.Plugin.Async]
  end

  @doc false
  def pipeline(plugins, resolution) do
    resolution_acc = resolution.acc
    Enum.reduce(plugins, [], fn plugin, pipeline ->
      plugin.pipeline(pipeline, resolution_acc)
    end)
    |> List.flatten
    |> Enum.dedup
  end
end
