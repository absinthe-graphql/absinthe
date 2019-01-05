defmodule Absinthe.Phase.Telemetry do
  @moduledoc """
  Gather and report telemetry about a pipeline.
  """
  @telemetry_event [:absinthe, :query]

  use Absinthe.Phase

  def run(blueprint, _options \\ []) do
    with %{start_time: start_time, start_time_mono: start_time_mono} <- blueprint.telemetry,
         %{emitter: operation} <- blueprint.execution.result do
      :telemetry.execute(
        @telemetry_event,
        %{
          start_time: start_time,
          duration: System.monotonic_time() - start_time_mono
        },
        %{
          query: query(blueprint.telemetry.source),
          schema: blueprint.schema,
          variables: blueprint.telemetry.variables,
          operation_complexity: operation.complexity,
          operation_type: operation.type,
          operation_name: operation.name
        }
      )
    end

    {:ok, blueprint}
  end

  defp query(%Absinthe.Language.Source{body: query}), do: query
  defp query(query), do: query
end
