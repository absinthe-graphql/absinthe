defmodule Absinthe.AsyncTaskWrapper do
  @moduledoc """
  Provides a way to extend Absinthe's asynchronous resolution.

  Trace span propagation, Logger metadata, and other mechanisms use the process dictionary to
  pass information down the call stack without needing every function to take it as an argument
  and pass it down. Absinthe's asynchronous resolution disrupts this style of propagation. To
  repair it, you can either:

  * Replace all use of `Absinthe.Middleware.Async` with `Task.async/1` and the closure of your
    choice, or

  * Implement this behaviour and configure Absinthe to use it.

  ## Example

  To propagate your app's custom `:myapp_span_context` value from the process dictionary of the
  blueprint to any async resolver function, define a module with a `c:wrap/2` callback...

  ```elixir
  defmodule MyApp.AsyncTaskWrapper do
    @behaviour Absinthe.AsyncTaskWrapper
    @impl true
    def wrap(fun, _) do
      ctx = Process.get(:myapp_span_context)
      fn ->
        Process.put(:myapp_span_context, ctx)
        apply(fun, [])
      end
    end
  end
  ```

  ... and configure Absinthe to use it:
  ```elixir
  config :absinthe, async_task_wrapper: MyApp.AsyncTaskWrapper
  ```

  See also:

  * `Logger.metadata/0`
  * `Logger.metadata/1`
  * `Process.get/1`
  * `Process.put/2`
  * `Task.async/1`
  * `Task.await/1`
  """

  alias Absinthe.Blueprint.Execution
  alias Absinthe.Resolution

  @doc """
  Wrap a function before its execution by `Task.async/1`.

  Called with the original function and either:

  *  The `t:Absinthe.Blueprint.Execution.t/0` via `Absinthe.Middleware.Batch`, or
  *  The `t:Absinthe.Resolution.t/0` via `Absinthe.Middleware.Async`.

  Your `c:wrap/2` [MUST] return a zero-arity anonymous function, as expected by `Task.async/1`.

  [MUST]: https://tools.ietf.org/html/rfc2119#section-1
  """
  @callback wrap(fun :: (() -> any()), exec :: Execution.t() | Resolution.t()) :: (() -> any())

  @doc """
  Starts a task that must be awaited on, after wrapping it as configured.

  Intended for use by Absinthe and its plugins.
  """
  def async(fun, res) when is_function(fun, 0) do
    fun =
      case Application.get_env(:absinthe, :async_task_wrapper) do
        nil -> fun
        module -> apply(module, :wrap, [fun, res])
      end

    Task.async(fun)
  end
end
