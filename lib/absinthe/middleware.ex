defmodule Absinthe.Middleware do
  @moduledoc """
  Defines Resolution Middleware Behaviour

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
  This is the main middleware callback.

  It receives an `%Absinthe.Resolution{}` struct and it needs to return an
  `%Absinthe.Resolution{}` struct. The second argument will be whatever value
  was passed to the `plug` call that setup the middleware.
  """
  @callback call(Absinthe.Resolution.t, term) :: Absinthe.Resolution.t

  @doc """
  Optional callback to setup the resolution accumulator prior to resolution.

  NOTE: This function is given the full accumulator. Namespacing is suggested to
  avoid conflicts.
  """
  @callback before_resolution(resolution_acc :: Document.Resolution.acc) :: Document.Resolution.acc

  @doc """
  Optional callback to do something with the resolution accumulator after
  resolution.

  NOTE: This function is given the full accumulator. Namespacing is suggested to
  avoid conflicts.
  """
  @callback after_resolution(resolution_acc :: Document.Resolution.acc) :: Document.Resolution.acc

  @doc """
  Optional callback used to specify additional phases to run.

  Plugins may require additional resolution phases to be run. This function should
  use values set in the resolution accumulator to determine
  whether or not additional phases are required.

  NOTE: This function is given the whole pipeline to be inserted after the current
  phase completes.
  """
  @callback pipeline(next_pipeline :: Absinthe.Pipeline.t, resolution_acc :: map) :: Absinthe.Pipeline.t

  @optional_callbacks [
    before_resolution: 1,
    after_resolution: 1,
    pipeline: 2,
  ]

  @doc """
  Build a middleware Tuple.

  Internally Absinthe represents the middleware to be run on a field as a list
  of tuples. This representation however ought not to be the concern of library
  users, so we recommend using this function instead which will always return
  whatever the current representation is.

  ## Examples
  ```
  Absinthe.Middleware.plug(MyApp.Authorization)
  Absinthe.Middleware.plug(MyApp.Authorization, some_option: :foo)
  ```
  """
  def plug(middleware, opts \\ [])
  def plug({_, _} = middleware, opts) do
    {middleware, opts}
  end
  def plug(module, opts) do
    plug({module, :call}, opts)
  end

  @doc """
  Returns the list of default plugins.
  """
  def defaults() do
    [Absinthe.Middleware.Batch, Absinthe.Middleware.Async]
  end

  @doc """
  Returns the list of phases necessary to run resolution again.
  """
  def resolution_phases() do
    [
      Absinthe.Phase.Document.Execution.BeforeResolution,
      Absinthe.Phase.Document.Execution.Resolution,
      Absinthe.Phase.Document.Execution.AfterResolution,
    ]
  end

  @doc false
  def pipeline(plugins, resolution_acc) do
    Enum.reduce(plugins, [], fn plugin, pipeline ->
      plugin.pipeline(pipeline, resolution_acc)
    end)
    |> Enum.dedup
    |> List.flatten
  end
end
