defmodule Absinthe.Middleware.AutoDeferStream do
  @moduledoc """
  Middleware that automatically suggests or applies @defer and @stream directives
  based on field complexity and performance characteristics.

  This middleware can:
  - Analyze field complexity and suggest defer/stream
  - Automatically apply defer/stream to expensive fields
  - Learn from execution patterns to optimize future queries
  """

  @behaviour Absinthe.Middleware

  require Logger

  @default_config %{
    # Thresholds for automatic optimization
    # Complexity threshold for auto-defer
    auto_defer_threshold: 100,
    # List size threshold for auto-stream
    auto_stream_threshold: 50,
    # Default initial count for auto-stream
    auto_stream_initial_count: 10,

    # Learning configuration
    enable_learning: true,
    # Sample 10% of queries for learning
    learning_sample_rate: 0.1,

    # Field-specific hints
    field_hints: %{},

    # Performance history
    performance_history: %{},

    # Modes
    # :suggest | :auto | :off
    mode: :suggest,

    # Complexity weights
    complexity_weights: %{
      resolver_time: 1.0,
      data_size: 0.5,
      depth: 0.3
    }
  }

  @doc """
  Middleware call that analyzes and potentially modifies the query.
  """
  def call(resolution, config \\ %{}) do
    config = Map.merge(@default_config, config)

    case config.mode do
      :off ->
        resolution

      :suggest ->
        suggest_optimizations(resolution, config)

      :auto ->
        apply_optimizations(resolution, config)
    end
  end

  @doc """
  Analyze a field and determine if it should be deferred.
  """
  def should_defer?(field, resolution, config) do
    # Check if field is already deferred
    if has_defer_directive?(field) do
      false
    else
      # Calculate field complexity
      complexity = calculate_field_complexity(field, resolution, config)

      # Check against threshold
      complexity > config.auto_defer_threshold
    end
  end

  @doc """
  Analyze a list field and determine if it should be streamed.
  """
  def should_stream?(field, resolution, config) do
    # Check if field is already streamed
    if has_stream_directive?(field) do
      false
    else
      # Must be a list type
      if not is_list_field?(field) do
        false
      else
        # Estimate list size
        estimated_size = estimate_list_size(field, resolution, config)

        # Check against threshold
        estimated_size > config.auto_stream_threshold
      end
    end
  end

  @doc """
  Get optimization suggestions for a query.
  """
  def get_suggestions(blueprint, config \\ %{}) do
    config = Map.merge(@default_config, config)
    suggestions = []

    # Walk the blueprint and collect suggestions
    Absinthe.Blueprint.prewalk(blueprint, suggestions, fn
      %{__struct__: Absinthe.Blueprint.Document.Field} = field, acc ->
        suggestion = analyze_field_for_suggestions(field, config)

        if suggestion do
          {field, [suggestion | acc]}
        else
          {field, acc}
        end

      node, acc ->
        {node, acc}
    end)
    |> elem(1)
    |> Enum.reverse()
  end

  @doc """
  Learn from execution results to improve future suggestions.
  """
  def learn_from_execution(field_path, execution_time, data_size, config) do
    if config.enable_learning do
      update_performance_history(
        field_path,
        %{
          execution_time: execution_time,
          data_size: data_size,
          timestamp: System.system_time(:second)
        },
        config
      )
    end
  end

  # Private functions

  defp suggest_optimizations(resolution, config) do
    field = resolution.definition

    cond do
      should_defer?(field, resolution, config) ->
        add_suggestion(resolution, :defer, field)

      should_stream?(field, resolution, config) ->
        add_suggestion(resolution, :stream, field)

      true ->
        resolution
    end
  end

  defp apply_optimizations(resolution, config) do
    field = resolution.definition

    cond do
      should_defer?(field, resolution, config) ->
        apply_defer(resolution, config)

      should_stream?(field, resolution, config) ->
        apply_stream(resolution, config)

      true ->
        resolution
    end
  end

  defp calculate_field_complexity(field, resolution, config) do
    base_complexity = get_base_complexity(field)

    # Factor in historical performance data
    historical_factor =
      if config.enable_learning do
        get_historical_complexity(field, config)
      else
        1.0
      end

    # Factor in depth
    depth_factor = length(resolution.path) * config.complexity_weights.depth

    # Factor in child selections
    child_factor = count_child_selections(field) * 10

    base_complexity * historical_factor + depth_factor + child_factor
  end

  defp get_base_complexity(field) do
    # Get complexity from field definition or default
    case field do
      %{complexity: complexity} when is_number(complexity) ->
        complexity

      %{complexity: fun} when is_function(fun) ->
        # Call complexity function with default child complexity
        fun.(0, 1)

      _ ->
        # Default complexity based on type
        if is_list_field?(field), do: 50, else: 10
    end
  end

  defp get_historical_complexity(field, config) do
    field_path = field_path(field)

    case Map.get(config.performance_history, field_path) do
      nil ->
        1.0

      history ->
        # Calculate average execution time
        avg_time = average_execution_time(history)

        # Convert to complexity factor (ms to factor)
        cond do
          # Fast field
          avg_time < 10 -> 0.5
          # Normal field
          avg_time < 50 -> 1.0
          # Slow field
          avg_time < 200 -> 2.0
          # Very slow field
          true -> 5.0
        end
    end
  end

  defp estimate_list_size(field, resolution, config) do
    # Check for limit/first arguments
    limit = get_argument_value(resolution.arguments, [:limit, :first])

    if limit do
      limit
    else
      # Use historical data or default estimate
      field_path = field_path(field)

      case Map.get(config.performance_history, field_path) do
        nil ->
          # Default estimate
          100

        history ->
          average_data_size(history)
      end
    end
  end

  defp has_defer_directive?(field) do
    field.directives
    |> Enum.any?(&(&1.name == "defer"))
  end

  defp has_stream_directive?(field) do
    field.directives
    |> Enum.any?(&(&1.name == "stream"))
  end

  defp is_list_field?(field) do
    # Check if the field type is a list
    case field.schema_node do
      %{type: type} ->
        is_list_type?(type)

      _ ->
        false
    end
  end

  defp is_list_type?(%Absinthe.Type.List{}), do: true
  defp is_list_type?(%Absinthe.Type.NonNull{of_type: inner}), do: is_list_type?(inner)
  defp is_list_type?(_), do: false

  defp count_child_selections(field) do
    case field do
      %{selections: selections} when is_list(selections) ->
        length(selections)

      _ ->
        0
    end
  end

  defp field_path(field) do
    # Generate a unique path for the field
    field.name
  end

  defp get_argument_value(arguments, names) do
    Enum.find_value(names, fn name ->
      Map.get(arguments, name)
    end)
  end

  defp add_suggestion(resolution, type, field) do
    suggestion = build_suggestion(type, field)

    # Add to resolution private data
    suggestions = Map.get(resolution.private, :optimization_suggestions, [])

    put_in(
      resolution.private[:optimization_suggestions],
      [suggestion | suggestions]
    )
  end

  defp build_suggestion(:defer, field) do
    %{
      type: :defer,
      field: field.name,
      path: field.source_location,
      message: "Consider adding @defer to field '#{field.name}' - high complexity detected",
      suggested_directive: "@defer(label: \"#{field.name}\")"
    }
  end

  defp build_suggestion(:stream, field) do
    %{
      type: :stream,
      field: field.name,
      path: field.source_location,
      message: "Consider adding @stream to field '#{field.name}' - large list detected",
      suggested_directive: "@stream(initialCount: 10, label: \"#{field.name}\")"
    }
  end

  defp apply_defer(resolution, config) do
    # Add defer flag to the field
    field =
      put_in(
        resolution.definition.flags[:defer],
        %{label: "auto_#{resolution.definition.name}", enabled: true}
      )

    %{resolution | definition: field}
  end

  defp apply_stream(resolution, config) do
    # Add stream flag to the field
    field =
      put_in(
        resolution.definition.flags[:stream],
        %{
          label: "auto_#{resolution.definition.name}",
          initial_count: config.auto_stream_initial_count,
          enabled: true
        }
      )

    %{resolution | definition: field}
  end

  defp update_performance_history(field_path, metrics, config) do
    history = Map.get(config.performance_history, field_path, [])

    # Keep last 100 entries
    updated_history =
      [metrics | history]
      |> Enum.take(100)

    put_in(config.performance_history[field_path], updated_history)
  end

  defp average_execution_time(history) do
    times = Enum.map(history, & &1.execution_time)
    Enum.sum(times) / length(times)
  end

  defp average_data_size(history) do
    sizes = Enum.map(history, & &1.data_size)
    round(Enum.sum(sizes) / length(sizes))
  end

  defp analyze_field_for_suggestions(field, config) do
    complexity = get_base_complexity(field)

    cond do
      complexity > config.auto_defer_threshold and not has_defer_directive?(field) ->
        build_suggestion(:defer, field)

      is_list_field?(field) and not has_stream_directive?(field) ->
        build_suggestion(:stream, field)

      true ->
        nil
    end
  end
end

defmodule Absinthe.Middleware.AutoDeferStream.Analyzer do
  @moduledoc """
  Analyzer for collecting performance metrics and generating optimization reports.
  """

  use GenServer

  # Analyze every minute
  @analysis_interval 60_000

  defstruct [
    :config,
    :metrics,
    :suggestions,
    :learning_data
  ]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    # Schedule periodic analysis
    schedule_analysis()

    {:ok,
     %__MODULE__{
       config: Map.new(opts),
       metrics: %{},
       suggestions: [],
       learning_data: %{}
     }}
  end

  @doc """
  Record execution metrics for a field.
  """
  def record_metrics(field_path, metrics) do
    GenServer.cast(__MODULE__, {:record_metrics, field_path, metrics})
  end

  @doc """
  Get optimization report.
  """
  def get_report do
    GenServer.call(__MODULE__, :get_report)
  end

  @impl true
  def handle_cast({:record_metrics, field_path, metrics}, state) do
    updated_metrics =
      Map.update(state.metrics, field_path, [metrics], &[metrics | &1])

    {:noreply, %{state | metrics: updated_metrics}}
  end

  @impl true
  def handle_call(:get_report, _from, state) do
    report = generate_report(state)
    {:reply, report, state}
  end

  @impl true
  def handle_info(:analyze, state) do
    # Analyze collected metrics
    state = analyze_metrics(state)

    # Schedule next analysis
    schedule_analysis()

    {:noreply, state}
  end

  defp schedule_analysis do
    Process.send_after(self(), :analyze, @analysis_interval)
  end

  defp analyze_metrics(state) do
    suggestions =
      state.metrics
      |> Enum.map(fn {field_path, metrics} ->
        analyze_field_metrics(field_path, metrics)
      end)
      |> Enum.filter(& &1)

    %{state | suggestions: suggestions}
  end

  defp analyze_field_metrics(field_path, metrics) do
    avg_time = average(Enum.map(metrics, & &1.execution_time))
    avg_size = average(Enum.map(metrics, & &1.data_size))

    cond do
      avg_time > 100 ->
        %{
          field: field_path,
          type: :defer,
          reason: "Average execution time #{avg_time}ms exceeds threshold"
        }

      avg_size > 100 ->
        %{
          field: field_path,
          type: :stream,
          reason: "Average data size #{avg_size} items exceeds threshold"
        }

      true ->
        nil
    end
  end

  defp generate_report(state) do
    %{
      total_fields_analyzed: map_size(state.metrics),
      suggestions: state.suggestions,
      top_slow_fields: get_top_slow_fields(state.metrics, 10),
      top_large_fields: get_top_large_fields(state.metrics, 10)
    }
  end

  defp get_top_slow_fields(metrics, limit) do
    metrics
    |> Enum.map(fn {path, data} ->
      {path, average(Enum.map(data, & &1.execution_time))}
    end)
    |> Enum.sort_by(&elem(&1, 1), :desc)
    |> Enum.take(limit)
  end

  defp get_top_large_fields(metrics, limit) do
    metrics
    |> Enum.map(fn {path, data} ->
      {path, average(Enum.map(data, & &1.data_size))}
    end)
    |> Enum.sort_by(&elem(&1, 1), :desc)
    |> Enum.take(limit)
  end

  defp average([]), do: 0
  defp average(list), do: Enum.sum(list) / length(list)
end
