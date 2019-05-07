defmodule Absinthe.Middleware.Telemetry do
  @moduledoc """
  Gather and report telemetry about an individual field resolution
  """
  @field_start [:absinthe, :resolve, :field, :start]
  @field [:absinthe, :resolve, :field]

  @behaviour Absinthe.Middleware

  @impl Absinthe.Middleware
  def call(resolution, _) do
    id = :erlang.unique_integer()
    start_time = System.system_time()
    start_time_mono = System.monotonic_time()

    :telemetry.execute(@field_start, %{start_time: start_time}, %{id: id})

    %{
      resolution
      | middleware:
          resolution.middleware ++
            [
              {{__MODULE__, :on_complete},
               %{
                 id: id,
                 start_time: start_time,
                 start_time_mono: start_time_mono,
                 middleware: resolution.middleware
               }}
            ]
    }
  end

  def on_complete(
        %{state: :resolved} = resolution,
        %{
          id: id,
          start_time: start_time,
          start_time_mono: start_time_mono,
          middleware: middleware
        }
      ) do
    end_time_mono = System.monotonic_time()

    :telemetry.execute(
      @field,
      %{duration: end_time_mono - start_time_mono},
      %{
        id: id,
        start_time: start_time,
        middleware: middleware,
        resolution: resolution
      }
    )

    resolution
  end
end
