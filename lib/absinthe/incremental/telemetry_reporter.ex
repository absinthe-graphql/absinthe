defmodule Absinthe.Incremental.TelemetryReporter do
  @moduledoc """
  Reports telemetry events for incremental delivery operations.
  """

  use GenServer
  require Logger

  @events [
    [:absinthe, :incremental, :defer, :start],
    [:absinthe, :incremental, :defer, :stop],
    [:absinthe, :incremental, :stream, :start],
    [:absinthe, :incremental, :stream, :stop],
    [:absinthe, :incremental, :error]
  ]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Attach telemetry handlers
    Enum.each(@events, fn event ->
      :telemetry.attach(
        {__MODULE__, event},
        event,
        &handle_event/4,
        nil
      )
    end)

    {:ok, %{}}
  end

  @impl true
  def terminate(_reason, _state) do
    # Detach telemetry handlers
    Enum.each(@events, fn event ->
      :telemetry.detach({__MODULE__, event})
    end)

    :ok
  end

  defp handle_event([:absinthe, :incremental, :defer, :start], _measurements, metadata, _config) do
    Logger.debug(
      "Defer operation started - label: #{metadata.label}, path: #{inspect(metadata.path)}"
    )
  end

  defp handle_event([:absinthe, :incremental, :defer, :stop], measurements, metadata, _config) do
    duration_ms = System.convert_time_unit(measurements.duration, :native, :millisecond)

    Logger.debug(
      "Defer operation completed - label: #{metadata.label}, duration: #{duration_ms}ms"
    )
  end

  defp handle_event([:absinthe, :incremental, :stream, :start], _measurements, metadata, _config) do
    Logger.debug(
      "Stream operation started - label: #{metadata.label}, initial_count: #{metadata.initial_count}"
    )
  end

  defp handle_event([:absinthe, :incremental, :stream, :stop], measurements, metadata, _config) do
    duration_ms = System.convert_time_unit(measurements.duration, :native, :millisecond)

    Logger.debug(
      "Stream operation completed - label: #{metadata.label}, " <>
        "items_streamed: #{metadata.items_count}, duration: #{duration_ms}ms"
    )
  end

  defp handle_event([:absinthe, :incremental, :error], _measurements, metadata, _config) do
    Logger.error(
      "Incremental delivery error - type: #{metadata.error_type}, " <>
        "operation: #{metadata.operation_id}, details: #{inspect(metadata.error)}"
    )
  end
end
