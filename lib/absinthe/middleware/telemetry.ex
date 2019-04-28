defmodule Absinthe.Middleware.Telemetry do
  @moduledoc """
  Gather and report telemetry about an individual resolver function
  """
  @telemetry_event [:absinthe, :resolver]

  @behaviour Absinthe.Middleware

  @impl Absinthe.Middleware
  def call(%{middleware: [{{Absinthe.Resolution, :call}, resolver_fun} | _]} = resolution, _) do
    on_complete =
      {{__MODULE__, :on_complete},
       [
         start_time: System.system_time(),
         start_time_mono: System.monotonic_time(),
         resolver_fun: resolver_fun
       ]}

    %{resolution | middleware: resolution.middleware ++ [on_complete]}
  end

  def call(resolution, _config), do: resolution

  def on_complete(%{state: :resolved} = resolution,
        start_time: start_time,
        start_time_mono: start_time_mono,
        resolver_fun: resolver_fun
      ) do
    :telemetry.execute(
      @telemetry_event,
      %{
        duration: System.monotonic_time() - start_time_mono
      },
      %{
        start_time: start_time,
        resolver_fun: resolver_fun,
        resolution: resolution
      }
    )

    resolution
  end
end
