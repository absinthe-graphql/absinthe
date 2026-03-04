defmodule Absinthe.Pipeline.Incremental do
  @moduledoc """
  Pipeline modifications for incremental delivery support.

  This module provides functions to modify the standard Absinthe pipeline
  to support @defer and @stream directives.
  """

  alias Absinthe.{Pipeline, Phase, Blueprint}
  alias Absinthe.Phase.Document.Execution.StreamingResolution
  alias Absinthe.Incremental.Config

  @doc """
  Modify a pipeline to support incremental delivery.

  This function:
  1. Replaces the standard resolution phase with streaming resolution
  2. Adds incremental delivery configuration
  3. Inserts monitoring phases if telemetry is enabled

  ## Examples

      pipeline = 
        MySchema
        |> Pipeline.for_document(opts)
        |> Pipeline.Incremental.enable()
  """
  @spec enable(Pipeline.t(), Keyword.t()) :: Pipeline.t()
  def enable(pipeline, opts \\ []) do
    config = Config.from_options(opts)

    if Config.enabled?(config) do
      pipeline
      |> replace_resolution_phase(config)
      |> insert_monitoring_phases(config)
      |> add_incremental_config(config)
    else
      pipeline
    end
  end

  @doc """
  Check if a pipeline has incremental delivery enabled.
  """
  @spec enabled?(Pipeline.t()) :: boolean()
  def enabled?(pipeline) do
    Enum.any?(pipeline, fn
      {StreamingResolution, _} -> true
      _ -> false
    end)
  end

  @doc """
  Insert incremental delivery phases at the appropriate points.

  This is useful for adding custom phases that need to run
  before or after specific incremental delivery operations.
  """
  @spec insert(Pipeline.t(), atom(), module(), Keyword.t()) :: Pipeline.t()
  def insert(pipeline, position, phase_module, opts \\ []) do
    phase = {phase_module, opts}

    case position do
      :before_streaming ->
        insert_before_phase(pipeline, StreamingResolution, phase)

      :after_streaming ->
        insert_after_phase(pipeline, StreamingResolution, phase)

      :before_defer ->
        insert_before_defer(pipeline, phase)

      :after_defer ->
        insert_after_defer(pipeline, phase)

      :before_stream ->
        insert_before_stream(pipeline, phase)

      :after_stream ->
        insert_after_stream(pipeline, phase)

      _ ->
        pipeline
    end
  end

  @doc """
  Add a custom handler for deferred operations.

  This allows you to customize how deferred fragments are processed.
  """
  @spec on_defer(Pipeline.t(), (Blueprint.t() -> Blueprint.t())) :: Pipeline.t()
  def on_defer(pipeline, handler) do
    insert(pipeline, :before_defer, __MODULE__.DeferHandler, handler: handler)
  end

  @doc """
  Add a custom handler for streamed operations.

  This allows you to customize how streamed lists are processed.
  """
  @spec on_stream(Pipeline.t(), (Blueprint.t() -> Blueprint.t())) :: Pipeline.t()
  def on_stream(pipeline, handler) do
    insert(pipeline, :before_stream, __MODULE__.StreamHandler, handler: handler)
  end

  @doc """
  Configure batching for streamed operations.

  This allows you to control how items are batched when streaming.
  """
  @spec configure_batching(Pipeline.t(), Keyword.t()) :: Pipeline.t()
  def configure_batching(pipeline, opts) do
    batch_size = Keyword.get(opts, :batch_size, 10)
    batch_delay = Keyword.get(opts, :batch_delay, 0)

    add_phase_option(pipeline, StreamingResolution,
      batch_size: batch_size,
      batch_delay: batch_delay
    )
  end

  @doc """
  Add error recovery for incremental delivery.

  This ensures that errors in deferred/streamed operations are handled gracefully.
  """
  @spec with_error_recovery(Pipeline.t()) :: Pipeline.t()
  def with_error_recovery(pipeline) do
    insert(pipeline, :after_streaming, __MODULE__.ErrorRecovery, [])
  end

  # Private functions

  defp replace_resolution_phase(pipeline, config) do
    Enum.map(pipeline, fn
      {Phase.Document.Execution.Resolution, opts} ->
        # Replace with streaming resolution
        {StreamingResolution, Keyword.put(opts, :config, config)}

      phase ->
        phase
    end)
  end

  defp insert_monitoring_phases(pipeline, %{enable_telemetry: true}) do
    pipeline
    |> insert_before_phase(StreamingResolution, {__MODULE__.TelemetryStart, []})
    |> insert_after_phase(StreamingResolution, {__MODULE__.TelemetryStop, []})
  end

  defp insert_monitoring_phases(pipeline, _), do: pipeline

  defp add_incremental_config(pipeline, config) do
    # Add config to all phases that might need it
    Enum.map(pipeline, fn
      {module, opts} when is_atom(module) ->
        {module, Keyword.put(opts, :incremental_config, config)}

      phase ->
        phase
    end)
  end

  defp insert_before_phase(pipeline, target_phase, new_phase) do
    {before, after_with_target} =
      Enum.split_while(pipeline, fn
        {^target_phase, _} -> false
        _ -> true
      end)

    before ++ [new_phase | after_with_target]
  end

  defp insert_after_phase(pipeline, target_phase, new_phase) do
    {before_with_target, after_target} =
      Enum.split_while(pipeline, fn
        {^target_phase, _} -> true
        _ -> false
      end)

    case after_target do
      [] -> before_with_target ++ [new_phase]
      _ -> before_with_target ++ [hd(after_target), new_phase | tl(after_target)]
    end
  end

  defp insert_before_defer(pipeline, phase) do
    # Insert before defer processing in streaming resolution
    insert_before_phase(pipeline, __MODULE__.DeferProcessor, phase)
  end

  defp insert_after_defer(pipeline, phase) do
    insert_after_phase(pipeline, __MODULE__.DeferProcessor, phase)
  end

  defp insert_before_stream(pipeline, phase) do
    insert_before_phase(pipeline, __MODULE__.StreamProcessor, phase)
  end

  defp insert_after_stream(pipeline, phase) do
    insert_after_phase(pipeline, __MODULE__.StreamProcessor, phase)
  end

  defp add_phase_option(pipeline, target_phase, new_opts) do
    Enum.map(pipeline, fn
      {^target_phase, opts} ->
        {target_phase, Keyword.merge(opts, new_opts)}

      phase ->
        phase
    end)
  end
end

defmodule Absinthe.Pipeline.Incremental.TelemetryStart do
  @moduledoc false
  use Absinthe.Phase

  alias Absinthe.Blueprint

  def run(blueprint, _opts) do
    start_time = System.monotonic_time()

    :telemetry.execute(
      [:absinthe, :incremental, :start],
      %{system_time: System.system_time()},
      %{
        operation_id: get_operation_id(blueprint),
        has_defer: has_defer?(blueprint),
        has_stream: has_stream?(blueprint)
      }
    )

    execution = Map.put(blueprint.execution, :incremental_start_time, start_time)
    blueprint = %{blueprint | execution: execution}
    {:ok, blueprint}
  end

  defp get_operation_id(blueprint) do
    execution = Map.get(blueprint, :execution, %{})
    context = Map.get(execution, :context, %{})
    streaming_context = Map.get(context, :__streaming__, %{})
    Map.get(streaming_context, :operation_id)
  end

  defp has_defer?(blueprint) do
    Blueprint.prewalk(blueprint, false, fn
      %{flags: %{defer: _}}, _acc -> {nil, true}
      node, acc -> {node, acc}
    end)
    |> elem(1)
  end

  defp has_stream?(blueprint) do
    Blueprint.prewalk(blueprint, false, fn
      %{flags: %{stream: _}}, _acc -> {nil, true}
      node, acc -> {node, acc}
    end)
    |> elem(1)
  end
end

defmodule Absinthe.Pipeline.Incremental.TelemetryStop do
  @moduledoc false
  use Absinthe.Phase

  def run(blueprint, _opts) do
    execution = Map.get(blueprint, :execution, %{})
    start_time = Map.get(execution, :incremental_start_time)
    duration = if start_time, do: System.monotonic_time() - start_time, else: 0

    context = Map.get(execution, :context, %{})
    streaming_context = Map.get(context, :__streaming__, %{})

    :telemetry.execute(
      [:absinthe, :incremental, :stop],
      %{duration: duration},
      %{
        operation_id: Map.get(streaming_context, :operation_id),
        deferred_count: length(Map.get(streaming_context, :deferred_fragments, [])),
        streamed_count: length(Map.get(streaming_context, :streamed_fields, []))
      }
    )

    {:ok, blueprint}
  end
end

defmodule Absinthe.Pipeline.Incremental.ErrorRecovery do
  @moduledoc false
  use Absinthe.Phase
  alias Absinthe.Incremental.ErrorHandler

  def run(blueprint, _opts) do
    streaming_context = get_in(blueprint, [:execution, :context, :__streaming__])

    if streaming_context && has_errors?(blueprint) do
      handle_errors(blueprint, streaming_context)
    else
      {:ok, blueprint}
    end
  end

  defp has_errors?(blueprint) do
    errors = get_in(blueprint, [:result, :errors]) || []
    not Enum.empty?(errors)
  end

  defp handle_errors(blueprint, streaming_context) do
    errors = get_in(blueprint, [:result, :errors]) || []

    Enum.each(errors, fn error ->
      context = %{
        operation_id: streaming_context[:operation_id],
        path: error[:path] || [],
        label: nil,
        error_type: classify_error(error),
        details: error
      }

      ErrorHandler.handle_streaming_error(error, context)
    end)

    {:ok, blueprint}
  end

  defp classify_error(%{extensions: %{code: "TIMEOUT"}}), do: :timeout
  defp classify_error(%{extensions: %{code: "DATALOADER_ERROR"}}), do: :dataloader_error
  defp classify_error(_), do: :resolution_error
end

defmodule Absinthe.Pipeline.Incremental.DeferHandler do
  @moduledoc false
  use Absinthe.Phase

  alias Absinthe.Blueprint

  def run(blueprint, opts) do
    handler = Keyword.get(opts, :handler, & &1)

    blueprint =
      Blueprint.prewalk(blueprint, fn
        %{flags: %{defer: _}} = node ->
          handler.(node)

        node ->
          node
      end)

    {:ok, blueprint}
  end
end

defmodule Absinthe.Pipeline.Incremental.StreamHandler do
  @moduledoc false
  use Absinthe.Phase

  alias Absinthe.Blueprint

  def run(blueprint, opts) do
    handler = Keyword.get(opts, :handler, & &1)

    blueprint =
      Blueprint.prewalk(blueprint, fn
        %{flags: %{stream: _}} = node ->
          handler.(node)

        node ->
          node
      end)

    {:ok, blueprint}
  end
end
