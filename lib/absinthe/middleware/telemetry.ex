defmodule Absinthe.Middleware.Telemetry do
  @moduledoc """
  Gather and report telemetry about an individual resolver function
  """
  @telemetry_event [:absinthe, :resolver]

  @behaviour Absinthe.Middleware

  @impl Absinthe.Middleware
  def call(resolution, _) do
    on_complete =
      {{__MODULE__, :on_complete},
       [
         start_time: System.system_time(),
         start_time_mono: System.monotonic_time(),
         middleware: resolution.middleware
       ]}

    %{resolution | middleware: resolution.middleware ++ [on_complete]}
  end

  def on_complete(%{state: :resolved} = resolution,
        start_time: start_time,
        start_time_mono: start_time_mono,
        middleware: middleware
      ) do
    :telemetry.execute(
      @telemetry_event,
      %{
        duration: System.monotonic_time() - start_time_mono
      },
      %{
        start_time: start_time,
        middleware: middleware,
        resolution: resolution
      }
    )

    resolution
  end
end
