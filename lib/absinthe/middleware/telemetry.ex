defmodule Absinthe.Middleware.Telemetry do
  @moduledoc """
  Gather and report telemetry about an individual resolver function
  """
  @telemetry_event [:absinthe, :resolver]

  @behaviour Absinthe.Middleware

  @impl Absinthe.Middleware
  def call(%{middleware: [{{Absinthe.Resolution, :call}, resolver_fn} | _]} = res, _config) do
    on_complete = [
      {{__MODULE__, :on_complete},
       [
         start_time: System.system_time(),
         start_time_mono: System.monotonic_time(),
         resolver_fn: resolver_fn
       ]}
    ]

    %{res | middleware: res.middleware ++ on_complete}
  end

  def call(res, _config), do: res

  def on_complete(%{state: :resolved} = res,
        start_time: start_time,
        start_time_mono: start_time_mono,
        resolver_fn: resolver_fn
      ) do
    :telemetry.execute(
      @telemetry_event,
      %{
        start_time: start_time,
        duration: System.monotonic_time() - start_time_mono
      },
      %{
        schema: res.schema,
        mfa: resolver_mfa(resolver_fn),
        arguments: res.arguments,
        path: Absinthe.Resolution.path(res),
        field_name: res.definition.name,
        field_type: Absinthe.Type.name(res.definition.schema_node.type, res.schema),
        parent_type: res.parent_type.name
      }
    )

    res
  end

  defp resolver_mfa({mod, fun}), do: {mod, fun, 3}

  defp resolver_mfa(fun) when is_function(fun) do
    info = :erlang.fun_info(fun)
    {info[:module], info[:name], info[:arity]}
  end
end
