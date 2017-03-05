defmodule Absinthe.Middleware do
  @moduledoc """
  Middleware enables custom resolution behaviour on a field.

  Middleware can be placed on a field in three different ways:

  1) Using the `Absinthe.Schema.Notation.plug/2` macro used inside a field definition
  2) Using the `middleware/2` callback in your schema. This is useful when you want to apply
  middleware to many fields
  3) Returning a `{:middleware, SomeMiddleware, opts}` tuple from a resolution function.

  ## Middleware Plug Macro

  Suppose you want to only allow authorized users to access a particular field.
  This is relatively generic logic, so you dont' want to do it inside resolution
  fields over and over. Let's build a small authorization middleware, and apply
  it to a field:

  ```
  defmodule MyApp.Web.Authentication do
    @behaviour Absinthe.Middleware

    def call(resolution, _opts) do
      case resolution.context do
        %{current_user: _} ->
          resolution
        _ ->
          resolution
          |> Absinthe.Resolution.put_result({:error, "unauthorized"})
      end
    end
  end
  ```

  By specifying `@behaviour Absinthe.Middleware` the compiler will ensure that
  we provide a `def call` callback. This function takes an `%Absinthe.Resolution{}`
  struct and will also need to return one such struct.

  On that struct there is a `context` key which holds the absinthe context. This
  is generally where things like the current user are placed. For more information
  on how the current user ends up in the context please see our full authentication
  guide on the website.

  Our `def call` function simply checks the context to see if there is a current
  user. If there is, we pass the resolution onward. If there is not, we update
  the resolution state to `:halt` and place an error result.

  A plugin is activated
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
