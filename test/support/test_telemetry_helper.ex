defmodule Absinthe.TestTelemetryHelper do
  def send_to_pid(event, measurements, metadata, config) do
    pid = config[:pid] || self()
    send(pid, {:telemetry_event, {event, measurements, metadata, config}})
  end
end
