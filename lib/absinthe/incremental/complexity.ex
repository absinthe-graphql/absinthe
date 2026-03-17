defmodule Absinthe.Incremental.Complexity do
  @moduledoc """
  Complexity analysis for incremental delivery operations.

  This module analyzes the complexity of queries with @defer and @stream directives,
  helping to prevent resource exhaustion from overly complex streaming operations.

  ## Per-Chunk Complexity

  In addition to analyzing total query complexity, this module supports per-chunk
  complexity analysis. This ensures that individual deferred fragments or streamed
  batches don't exceed reasonable complexity limits, even if the total complexity
  is acceptable.

  ## Usage

      # Analyze full query complexity
      {:ok, info} = Complexity.analyze(blueprint, %{max_complexity: 500})

      # Check per-chunk limits
      :ok = Complexity.check_chunk_limits(blueprint, %{max_chunk_complexity: 100})
  """

  alias Absinthe.{Blueprint, Type}

  @default_config %{
    # Base complexity costs
    field_cost: 1,
    object_cost: 1,
    list_cost: 10,

    # Incremental delivery multipliers
    # Deferred operations cost 50% more
    defer_multiplier: 1.5,
    # Streamed operations cost 2x more
    stream_multiplier: 2.0,
    # Nested defers are more expensive
    nested_defer_multiplier: 2.5,

    # Total query limits
    max_complexity: 1000,
    max_defer_depth: 3,
    # Maximum number of @defer directives
    max_defer_operations: 10,
    max_stream_operations: 10,
    max_total_streamed_items: 1000,

    # Per-chunk limits
    # Max complexity for any single deferred chunk
    max_chunk_complexity: 200,
    # Max complexity per stream batch
    max_stream_batch_complexity: 100,
    # Max complexity for initial response
    max_initial_complexity: 500
  }

  @type complexity_result :: {:ok, complexity_info()} | {:error, term()}

  @type complexity_info :: %{
          total_complexity: number(),
          defer_count: non_neg_integer(),
          stream_count: non_neg_integer(),
          max_defer_depth: non_neg_integer(),
          estimated_payloads: non_neg_integer(),
          breakdown: map(),
          chunk_complexities: list(chunk_info())
        }

  @type chunk_info :: %{
          type: :defer | :stream | :initial,
          label: String.t() | nil,
          path: list(),
          complexity: number()
        }

  @doc """
  Analyze the complexity of a blueprint with incremental delivery.

  Returns detailed complexity information including:
  - Total complexity score
  - Number of defer operations
  - Number of stream operations
  - Maximum defer nesting depth
  - Estimated number of payloads
  - Per-chunk complexity breakdown
  """
  @spec analyze(Blueprint.t(), map()) :: complexity_result()
  def analyze(blueprint, config \\ %{}) do
    config = Map.merge(@default_config, config)

    analysis = %{
      total_complexity: 0,
      defer_count: 0,
      stream_count: 0,
      max_defer_depth: 0,
      # Initial payload
      estimated_payloads: 1,
      breakdown: %{
        immediate: 0,
        deferred: 0,
        streamed: 0
      },
      chunk_complexities: [],
      defer_stack: [],
      current_chunk: :initial,
      current_chunk_complexity: 0,
      errors: []
    }

    result =
      analyze_document(
        blueprint.fragments ++ blueprint.operations,
        blueprint.schema,
        config,
        analysis
      )

    # Add the final initial chunk complexity
    result = finalize_initial_chunk(result)

    if Enum.empty?(result.errors) do
      {:ok, format_result(result)}
    else
      {:error, result.errors}
    end
  end

  @doc """
  Check if a query exceeds complexity limits including per-chunk limits.

  This is a convenience function that returns a simple pass/fail result.
  """
  @spec check_limits(Blueprint.t(), map()) :: :ok | {:error, term()}
  def check_limits(blueprint, config \\ %{}) do
    config = Map.merge(@default_config, config)

    case analyze(blueprint, config) do
      {:ok, info} ->
        cond do
          info.total_complexity > config.max_complexity ->
            {:error, {:complexity_exceeded, info.total_complexity, config.max_complexity}}

          info.defer_count > config.max_defer_operations ->
            {:error, {:too_many_defers, info.defer_count}}

          info.stream_count > config.max_stream_operations ->
            {:error, {:too_many_streams, info.stream_count}}

          info.max_defer_depth > config.max_defer_depth ->
            {:error, {:defer_too_deep, info.max_defer_depth}}

          true ->
            check_chunk_limits_from_info(info, config)
        end

      error ->
        error
    end
  end

  @doc """
  Check per-chunk complexity limits.

  This validates that each individual chunk (deferred fragment or stream batch)
  doesn't exceed its complexity limit. This is important because even if the total
  complexity is acceptable, having one extremely complex deferred chunk can cause
  problems.
  """
  @spec check_chunk_limits(Blueprint.t(), map()) :: :ok | {:error, term()}
  def check_chunk_limits(blueprint, config \\ %{}) do
    config = Map.merge(@default_config, config)

    case analyze(blueprint, config) do
      {:ok, info} ->
        check_chunk_limits_from_info(info, config)

      error ->
        error
    end
  end

  # Check chunk limits from analyzed info
  defp check_chunk_limits_from_info(info, config) do
    Enum.reduce_while(info.chunk_complexities, :ok, fn chunk, _acc ->
      case check_single_chunk(chunk, config) do
        :ok -> {:cont, :ok}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  defp check_single_chunk(%{type: :initial, complexity: complexity}, config) do
    if complexity > config.max_initial_complexity do
      {:error, {:initial_too_complex, complexity, config.max_initial_complexity}}
    else
      :ok
    end
  end

  defp check_single_chunk(%{type: :defer, complexity: complexity, label: label}, config) do
    if complexity > config.max_chunk_complexity do
      {:error, {:chunk_too_complex, :defer, label, complexity, config.max_chunk_complexity}}
    else
      :ok
    end
  end

  defp check_single_chunk(%{type: :stream, complexity: complexity, label: label}, config) do
    if complexity > config.max_stream_batch_complexity do
      {:error,
       {:chunk_too_complex, :stream, label, complexity, config.max_stream_batch_complexity}}
    else
      :ok
    end
  end

  @doc """
  Analyze the complexity of a specific deferred chunk.

  Use this to validate complexity when a deferred fragment is about to be resolved.
  """
  @spec analyze_chunk(map(), Blueprint.t(), map()) :: {:ok, number()} | {:error, term()}
  def analyze_chunk(chunk_info, blueprint, config \\ %{}) do
    config = Map.merge(@default_config, config)

    node = chunk_info.node

    chunk_analysis =
      analyze_node(
        node,
        blueprint.schema,
        config,
        %{
          total_complexity: 0,
          chunk_complexities: [],
          defer_count: 0,
          stream_count: 0,
          max_defer_depth: 0,
          estimated_payloads: 0,
          breakdown: %{immediate: 0, deferred: 0, streamed: 0},
          defer_stack: [],
          current_chunk: :chunk,
          current_chunk_complexity: 0,
          errors: []
        },
        0
      )

    complexity = chunk_analysis.total_complexity

    limit =
      case chunk_info do
        %{type: :defer} -> config.max_chunk_complexity
        %{type: :stream} -> config.max_stream_batch_complexity
        _ -> config.max_chunk_complexity
      end

    if complexity > limit do
      {:error, {:chunk_too_complex, chunk_info.type, chunk_info[:label], complexity, limit}}
    else
      {:ok, complexity}
    end
  end

  @doc """
  Calculate the cost of a specific field with incremental delivery.
  """
  @spec field_cost(Type.Field.t(), map(), map()) :: number()
  def field_cost(field, flags \\ %{}, config \\ %{}) do
    config = Map.merge(@default_config, config)
    base_cost = calculate_base_cost(field, config)

    multiplier =
      cond do
        Map.get(flags, :defer) -> config.defer_multiplier
        Map.get(flags, :stream) -> config.stream_multiplier
        true -> 1.0
      end

    base_cost * multiplier
  end

  @doc """
  Estimate the number of payloads for a streaming operation.
  """
  @spec estimate_payloads(Blueprint.t()) :: non_neg_integer()
  def estimate_payloads(blueprint) do
    streaming_context = get_in(blueprint, [:execution, :context, :__streaming__])

    if streaming_context do
      defer_count = length(Map.get(streaming_context, :deferred_fragments, []))
      _stream_count = length(Map.get(streaming_context, :streamed_fields, []))

      # Initial + each defer + estimated stream batches
      1 + defer_count + estimate_stream_batches(streaming_context)
    else
      1
    end
  end

  @doc """
  Get complexity summary suitable for telemetry/logging.
  """
  @spec summary(Blueprint.t(), map()) :: map()
  def summary(blueprint, config \\ %{}) do
    case analyze(blueprint, config) do
      {:ok, info} ->
        %{
          total: info.total_complexity,
          defers: info.defer_count,
          streams: info.stream_count,
          max_depth: info.max_defer_depth,
          payloads: info.estimated_payloads,
          chunks: length(info.chunk_complexities),
          max_chunk: info.chunk_complexities |> Enum.map(& &1.complexity) |> Enum.max(fn -> 0 end)
        }

      {:error, _} ->
        %{error: true}
    end
  end

  # Private functions

  defp analyze_document([], _schema, _config, analysis) do
    analysis
  end

  defp analyze_document([node | rest], schema, config, analysis) do
    analysis = analyze_node(node, schema, config, analysis, 0)
    analyze_document(rest, schema, config, analysis)
  end

  # Handle Operation nodes (root of queries/mutations/subscriptions)
  defp analyze_node(%Blueprint.Document.Operation{} = node, schema, config, analysis, depth) do
    analyze_selections(node.selections, schema, config, analysis, depth)
  end

  # Handle named fragments
  defp analyze_node(%Blueprint.Document.Fragment.Named{} = node, schema, config, analysis, depth) do
    analyze_selections(node.selections, schema, config, analysis, depth)
  end

  defp analyze_node(%Blueprint.Document.Fragment.Inline{} = node, schema, config, analysis, depth) do
    {analysis, in_defer} = check_defer_directive(node, config, analysis, depth)

    # If we entered a deferred fragment, track its complexity separately
    # and increment depth for nested content
    {analysis, nested_depth} =
      if in_defer do
        # Start a new chunk and increase depth for nested defers
        {%{
           analysis
           | current_chunk: {:defer, get_defer_label(node)},
             current_chunk_complexity: 0
         }, depth + 1}
      else
        {analysis, depth}
      end

    analysis = analyze_selections(node.selections, schema, config, analysis, nested_depth)

    # If we're leaving a deferred fragment, finalize its chunk complexity
    if in_defer do
      finalize_defer_chunk(analysis, get_defer_label(node), [])
    else
      analysis
    end
  end

  defp analyze_node(%Blueprint.Document.Fragment.Spread{} = node, schema, config, analysis, depth) do
    {analysis, _in_defer} = check_defer_directive(node, config, analysis, depth)
    # Would need to look up the fragment definition for full analysis
    analysis
  end

  defp analyze_node(%Blueprint.Document.Field{} = node, schema, config, analysis, depth) do
    # Calculate field cost
    base_cost = calculate_field_cost(node, schema, config)

    # Check for streaming
    analysis =
      if has_stream_directive?(node) do
        stream_config = get_stream_config(node)
        stream_cost = calculate_stream_cost(base_cost, stream_config, config)

        # Record stream chunk
        chunk = %{
          type: :stream,
          label: stream_config[:label],
          # Would need path tracking
          path: [],
          complexity: stream_cost
        }

        analysis
        |> update_in([:total_complexity], &(&1 + stream_cost))
        |> update_in([:stream_count], &(&1 + 1))
        |> update_in([:breakdown, :streamed], &(&1 + stream_cost))
        |> update_in([:chunk_complexities], &[chunk | &1])
        |> update_estimated_payloads(stream_config)
      else
        # Add to current chunk complexity
        analysis
        |> update_in([:total_complexity], &(&1 + base_cost))
        |> update_in([:breakdown, :immediate], &(&1 + base_cost))
        |> update_in([:current_chunk_complexity], &(&1 + base_cost))
      end

    # Analyze child selections
    if node.selections do
      analyze_selections(node.selections, schema, config, analysis, depth)
    else
      analysis
    end
  end

  defp analyze_node(_node, _schema, _config, analysis, _depth) do
    analysis
  end

  defp analyze_selections([], _schema, _config, analysis, _depth) do
    analysis
  end

  defp analyze_selections([selection | rest], schema, config, analysis, depth) do
    analysis = analyze_node(selection, schema, config, analysis, depth)
    analyze_selections(rest, schema, config, analysis, depth)
  end

  defp check_defer_directive(node, config, analysis, depth) do
    if has_defer_directive?(node) do
      defer_cost = calculate_defer_cost(node, config, depth)

      analysis =
        analysis
        |> update_in([:defer_count], &(&1 + 1))
        |> update_in([:total_complexity], &(&1 + defer_cost))
        |> update_in([:breakdown, :deferred], &(&1 + defer_cost))
        |> update_in([:max_defer_depth], &max(&1, depth + 1))
        |> update_in([:estimated_payloads], &(&1 + 1))

      {analysis, true}
    else
      {analysis, false}
    end
  end

  defp finalize_defer_chunk(analysis, label, path) do
    chunk = %{
      type: :defer,
      label: label,
      path: path,
      complexity: analysis.current_chunk_complexity
    }

    analysis
    |> update_in([:chunk_complexities], &[chunk | &1])
    |> Map.put(:current_chunk, :initial)
    |> Map.put(:current_chunk_complexity, 0)
  end

  defp finalize_initial_chunk(analysis) do
    if analysis.current_chunk_complexity > 0 do
      chunk = %{
        type: :initial,
        label: nil,
        path: [],
        complexity: analysis.current_chunk_complexity
      }

      update_in(analysis.chunk_complexities, &[chunk | &1])
    else
      analysis
    end
  end

  defp get_defer_label(node) do
    case Map.get(node, :directives) do
      nil ->
        nil

      directives ->
        directives
        |> Enum.find(&(&1.name == "defer"))
        |> case do
          nil -> nil
          directive -> get_directive_arg(directive, "label")
        end
    end
  end

  defp has_defer_directive?(node) do
    case Map.get(node, :directives) do
      nil -> false
      directives -> Enum.any?(directives, &(&1.name == "defer"))
    end
  end

  defp has_stream_directive?(node) do
    case Map.get(node, :directives) do
      nil -> false
      directives -> Enum.any?(directives, &(&1.name == "stream"))
    end
  end

  defp get_stream_config(node) do
    node.directives
    |> Enum.find(&(&1.name == "stream"))
    |> case do
      nil ->
        %{}

      directive ->
        %{
          initial_count: get_directive_arg(directive, "initialCount", 0),
          label: get_directive_arg(directive, "label")
        }
    end
  end

  defp get_directive_arg(directive, name, default \\ nil) do
    directive.arguments
    |> Enum.find(&(&1.name == name))
    |> case do
      nil -> default
      arg -> arg.value
    end
  end

  defp calculate_field_cost(field, _schema, config) do
    # Base cost for the field
    base = config.field_cost

    # Add cost for list types
    if is_list_type?(field) do
      base + config.list_cost
    else
      base
    end
  end

  defp calculate_stream_cost(base_cost, stream_config, config) do
    # Streaming adds complexity based on expected items
    estimated_items = estimate_list_size(stream_config)
    base_cost * config.stream_multiplier * (1 + estimated_items / 100)
  end

  defp calculate_defer_cost(_node, config, depth) do
    # Deeper nesting is more expensive
    multiplier =
      if depth > 1 do
        config.nested_defer_multiplier
      else
        config.defer_multiplier
      end

    config.object_cost * multiplier
  end

  defp calculate_base_cost(field, config) do
    type = Map.get(field, :type)

    if is_list_type?(type) do
      config.list_cost
    else
      config.field_cost
    end
  end

  defp is_list_type?(%Absinthe.Type.List{}), do: true
  defp is_list_type?(%Absinthe.Type.NonNull{of_type: inner}), do: is_list_type?(inner)
  defp is_list_type?(_), do: false

  defp estimate_list_size(stream_config) do
    # Estimate based on initial count and typical patterns
    initial = Map.get(stream_config, :initial_count, 0)

    # Assume lists are typically 10-100 items
    initial + 50
  end

  defp estimate_stream_batches(streaming_context) do
    streamed_fields = Map.get(streaming_context, :streamed_fields, [])

    Enum.reduce(streamed_fields, 0, fn field, acc ->
      # Estimate batches based on initial_count
      initial_count = Map.get(field, :initial_count, 0)
      # Estimate remaining items
      estimated_total = initial_count + 50
      batches = div(estimated_total - initial_count, 10) + 1
      acc + batches
    end)
  end

  defp update_estimated_payloads(analysis, stream_config) do
    # Estimate number of payloads based on stream configuration
    estimated_batches = div(estimate_list_size(stream_config), 10) + 1
    update_in(analysis.estimated_payloads, &(&1 + estimated_batches))
  end

  defp format_result(analysis) do
    %{
      total_complexity: analysis.total_complexity,
      defer_count: analysis.defer_count,
      stream_count: analysis.stream_count,
      max_defer_depth: analysis.max_defer_depth,
      estimated_payloads: analysis.estimated_payloads,
      breakdown: analysis.breakdown,
      chunk_complexities: Enum.reverse(analysis.chunk_complexities)
    }
  end
end
