defmodule Absinthe.Resolution.Plugin do
  @moduledoc """
  Defines Resolution Plugin Behaviour

  Plugins enable custom resolution behaviour on a field. A plugin is activated
  on field if its resolution function returns the following tuple instead of one
  of the usual `{:ok, value}` or `{:error, reason}` tuples:

  ```elixir
  {:plugin, NameOfPluginModule, term}
  ```

  Often a plugin will provide a helper function to return this, see `Absinthe.Resolution.Helpers.async/1`
  for an example.

  Plugins use the information placed in the third element of the plugin tuple
  along with values in the resolution accumulator to perform whatever logic they need.

  NOTE: All plugins that will be used must be listed on the schema.

  ## The Resolution Accumulator
  The resolution accumulator is just a map that is carried through the resolution process.
  The `Async` plugin uses it to flag whether or not a field has been executed asynchronously,
  which indicates that another resolution pass is needed to await that field. The `Batch`
  plugin uses it to hold all the information that will be used for batching.
  """

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

  The first argument to `init` is whatever `plugin_data` is. The second is the
  resolution accumulator.

  NOTE: This function is given the full accumulator. Namespacing is suggested to
  avoid conflicts.
  """
  @callback init(any, Document.Resolution.acc) :: {any :: Document.Resolution.acc}

  @doc """
  The default list of resolution plugins
  """
  def defaults do
    [Absinthe.Resolution.Plugin.Batch, Absinthe.Resolution.Plugin.Async]
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
