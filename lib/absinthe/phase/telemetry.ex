defmodule Absinthe.Phase.Telemetry do
  @moduledoc """
  Gather and report telemetry about an operation.
  """
  @operation_start [:absinthe, :execute, :operation, :start]
  @operation_stop [:absinthe, :execute, :operation, :stop]

  @subscription_start [:absinthe, :subscription, :publish, :start]
  @subscription_stop [:absinthe, :subscription, :publish, :stop]

  use Absinthe.Phase

  def run(blueprint, options) do
    event = Keyword.fetch!(options, :event)
    do_run(blueprint, event, options)
  end

  defp do_run(blueprint, [:execute, :operation, :start], options) do
    id = :erlang.unique_integer()
    system_time = System.system_time()
    start_time_mono = System.monotonic_time()

    :telemetry.execute(
      @operation_start,
      %{system_time: system_time},
      %{id: id, telemetry_span_context: id, blueprint: blueprint, options: options}
    )

    {:ok,
     %{
       blueprint
       | source: blueprint.input,
         telemetry: %{id: id, start_time_mono: start_time_mono}
     }}
  end

  defp do_run(blueprint, [:subscription, :publish, :start], options) do
    id = :erlang.unique_integer()
    system_time = System.system_time()
    start_time_mono = System.monotonic_time()

    :telemetry.execute(
      @subscription_start,
      %{system_time: system_time},
      %{id: id, telemetry_span_context: id, blueprint: blueprint, options: options}
    )

    {:ok,
     %{
       blueprint
       | telemetry: %{id: id, start_time_mono: start_time_mono}
     }}
  end

  defp do_run(blueprint, [:subscription, :publish, :stop], options) do
    end_time_mono = System.monotonic_time()

    with %{id: id, start_time_mono: start_time_mono} <- blueprint.telemetry do
      :telemetry.execute(
        @subscription_stop,
        %{duration: end_time_mono - start_time_mono},
        %{id: id, telemetry_span_context: id, blueprint: blueprint, options: options}
      )
    end

    {:ok, blueprint}
  end

  defp do_run(blueprint, [:execute, :operation, :stop], options) do
    end_time_mono = System.monotonic_time()

    with %{id: id, start_time_mono: start_time_mono} <- blueprint.telemetry do
      :telemetry.execute(
        @operation_stop,
        %{duration: end_time_mono - start_time_mono},
        %{id: id, telemetry_span_context: id, blueprint: blueprint, options: options}
      )
    end

    {:ok, blueprint}
  end
end
