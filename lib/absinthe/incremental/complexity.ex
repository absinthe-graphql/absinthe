defmodule Absinthe.Incremental.Complexity do
  @moduledoc """
  Complexity analysis for incremental delivery operations.
  
  This module analyzes the complexity of queries with @defer and @stream directives,
  helping to prevent resource exhaustion from overly complex streaming operations.
  """
  
  alias Absinthe.{Blueprint, Type}
  
  @default_config %{
    # Base complexity costs
    field_cost: 1,
    object_cost: 1,
    list_cost: 10,
    
    # Incremental delivery multipliers
    defer_multiplier: 1.5,      # Deferred operations cost 50% more
    stream_multiplier: 2.0,      # Streamed operations cost 2x more
    nested_defer_multiplier: 2.5, # Nested defers are more expensive
    
    # Limits
    max_complexity: 1000,
    max_defer_depth: 3,
    max_stream_operations: 10,
    max_total_streamed_items: 1000
  }
  
  @type complexity_result :: {:ok, complexity_info()} | {:error, term()}
  
  @type complexity_info :: %{
    total_complexity: number(),
    defer_count: non_neg_integer(),
    stream_count: non_neg_integer(),
    max_defer_depth: non_neg_integer(),
    estimated_payloads: non_neg_integer(),
    breakdown: map()
  }
  
  @doc """
  Analyze the complexity of a blueprint with incremental delivery.
  
  Returns detailed complexity information including:
  - Total complexity score
  - Number of defer operations
  - Number of stream operations
  - Maximum defer nesting depth
  - Estimated number of payloads
  """
  @spec analyze(Blueprint.t(), map()) :: complexity_result()
  def analyze(blueprint, config \\ %{}) do
    config = Map.merge(@default_config, config)
    
    analysis = %{
      total_complexity: 0,
      defer_count: 0,
      stream_count: 0,
      max_defer_depth: 0,
      estimated_payloads: 1,  # Initial payload
      breakdown: %{
        immediate: 0,
        deferred: 0,
        streamed: 0
      },
      defer_stack: [],
      errors: []
    }
    
    result = analyze_document(blueprint.fragments ++ blueprint.operations, blueprint.schema, config, analysis)
    
    if Enum.empty?(result.errors) do
      {:ok, format_result(result)}
    else
      {:error, result.errors}
    end
  end
  
  @doc """
  Check if a query exceeds complexity limits.
  
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
            :ok
        end
        
      error ->
        error
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
  
  # Private functions
  
  defp analyze_document([], _schema, _config, analysis) do
    analysis
  end
  
  defp analyze_document([node | rest], schema, config, analysis) do
    analysis = analyze_node(node, schema, config, analysis, 0)
    analyze_document(rest, schema, config, analysis)
  end
  
  defp analyze_node(%Blueprint.Document.Fragment.Inline{} = node, schema, config, analysis, depth) do
    analysis = check_defer_directive(node, config, analysis, depth)
    analyze_selections(node.selections, schema, config, analysis, depth)
  end
  
  defp analyze_node(%Blueprint.Document.Fragment.Spread{} = node, schema, config, analysis, depth) do
    analysis = check_defer_directive(node, config, analysis, depth)
    # Would need to look up the fragment definition
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
        
        analysis
        |> update_in([:total_complexity], &(&1 + stream_cost))
        |> update_in([:stream_count], &(&1 + 1))
        |> update_in([:breakdown, :streamed], &(&1 + stream_cost))
        |> update_estimated_payloads(stream_config)
      else
        analysis
        |> update_in([:total_complexity], &(&1 + base_cost))
        |> update_in([:breakdown, :immediate], &(&1 + base_cost))
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
      
      analysis
      |> update_in([:defer_count], &(&1 + 1))
      |> update_in([:total_complexity], &(&1 + defer_cost))
      |> update_in([:breakdown, :deferred], &(&1 + defer_cost))
      |> update_in([:max_defer_depth], &max(&1, depth + 1))
      |> update_in([:estimated_payloads], &(&1 + 1))
    else
      analysis
    end
  end
  
  defp has_defer_directive?(node) do
    case Map.get(node, :directives) do
      nil -> false
      directives -> Enum.any?(directives, & &1.name == "defer")
    end
  end
  
  defp has_stream_directive?(node) do
    case Map.get(node, :directives) do
      nil -> false
      directives -> Enum.any?(directives, & &1.name == "stream")
    end
  end
  
  defp get_stream_config(node) do
    node.directives
    |> Enum.find(& &1.name == "stream")
    |> case do
      nil -> %{}
      directive ->
        %{
          initial_count: get_directive_arg(directive, "initialCount", 0),
          label: get_directive_arg(directive, "label")
        }
    end
  end
  
  defp get_directive_arg(directive, name, default \\ nil) do
    directive.arguments
    |> Enum.find(& &1.name == name)
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
    if Type.list?(field.type) do
      config.list_cost
    else
      config.field_cost
    end
  end
  
  defp is_list_type?(field) do
    # Check if the field type is a list
    # This would need proper type introspection
    Map.get(field, :type_name) |> to_string() |> String.contains?("List")
  end
  
  defp estimate_list_size(stream_config) do
    # Estimate based on initial count and typical patterns
    initial = Map.get(stream_config, :initial_count, 0)
    
    # Assume lists are typically 10-100 items
    initial + 50
  end
  
  defp estimate_stream_batches(streaming_context) do
    streamed_fields = Map.get(streaming_context, :streamed_fields, [])
    
    Enum.reduce(streamed_fields, 0, fn field, acc ->
      # Estimate 5 batches per streamed field
      acc + 5
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
      breakdown: analysis.breakdown
    }
  end
end

defmodule Absinthe.Middleware.IncrementalComplexity do
  @moduledoc """
  Middleware to enforce complexity limits for incremental delivery.
  
  Add this middleware to your schema to automatically check and enforce
  complexity limits for queries with @defer and @stream.
  """
  
  @behaviour Absinthe.Middleware
  
  alias Absinthe.Incremental.Complexity
  
  def call(resolution, config) do
    blueprint = resolution.private[:blueprint]
    
    if blueprint && should_check?(resolution) do
      case Complexity.check_limits(blueprint, config) do
        :ok ->
          resolution
          
        {:error, reason} ->
          Absinthe.Resolution.put_result(
            resolution,
            {:error, format_error(reason)}
          )
      end
    else
      resolution
    end
  end
  
  defp should_check?(resolution) do
    # Only check on the root query/mutation/subscription
    resolution.path == []
  end
  
  defp format_error({:complexity_exceeded, actual, limit}) do
    "Query complexity #{actual} exceeds maximum of #{limit}"
  end
  
  defp format_error({:too_many_defers, count}) do
    "Too many defer operations: #{count}"
  end
  
  defp format_error({:too_many_streams, count}) do
    "Too many stream operations: #{count}"
  end
  
  defp format_error({:defer_too_deep, depth}) do
    "Defer nesting too deep: #{depth} levels"
  end
  
  defp format_error(reason) do
    "Complexity check failed: #{inspect(reason)}"
  end
end