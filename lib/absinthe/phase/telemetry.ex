defmodule Absinthe.Phase.Telemetry do
  @moduledoc """
  Gather and report telemetry about an operation.
  """
  @operation_start [:absinthe, :execute, :operation, :start]
  @operation_stop [:absinthe, :execute, :operation, :stop]
  @operation_exception [:absinthe, :execute, :operation, :exception]

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
         telemetry: %{
           id: id,
           start_time_mono: start_time_mono,
           span: :operation,
           options: options
         }
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
        %{duration: end_time_mono - start_time_mono, end_time_mono: end_time_mono},
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
        %{duration: end_time_mono - start_time_mono, end_time_mono: end_time_mono},
        %{id: id, telemetry_span_context: id, blueprint: blueprint, options: options}
      )
    end

    {:ok, blueprint}
  end

  @doc """
  Emit an operation `:exception` telemetry event when a phase raises, throws, or
  exits while an operation span is active.

  This is called by `Absinthe.Pipeline` for any phase that fails after the
  `[:execute, :operation, :start]` event has been emitted, so exceptions raised
  anywhere in the document pipeline (for example, in a resolver) surface as a
  `[:absinthe, :execute, :operation, :exception]` event.
  """
  def handle_pipeline_exception(
        %{telemetry: %{span: :operation, id: id, options: options}} = blueprint,
        kind,
        reason,
        stacktrace
      ) do
    :telemetry.execute(
      @operation_exception,
      %{},
      %{
        id: id,
        telemetry_span_context: id,
        blueprint: blueprint,
        options: options,
        kind: kind,
        reason: reason,
        stacktrace: stacktrace
      }
    )
  end

  def handle_pipeline_exception(_blueprint, _kind, _reason, _stacktrace), do: :ok
end
