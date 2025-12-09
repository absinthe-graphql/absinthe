defmodule Absinthe.Incremental.Config do
  @moduledoc """
  Configuration for incremental delivery features.
  
  This module manages configuration options for @defer and @stream directives,
  including resource limits, timeouts, and transport settings.
  """
  
  @default_config %{
    # Feature flags
    enabled: false,
    enable_defer: true,
    enable_stream: true,
    
    # Resource limits
    max_concurrent_streams: 100,
    max_stream_duration: 30_000,  # 30 seconds
    max_memory_mb: 500,
    max_pending_operations: 1000,
    
    # Batching settings
    default_stream_batch_size: 10,
    max_stream_batch_size: 100,
    enable_dataloader_batching: true,
    dataloader_timeout: 5_000,
    
    # Transport settings
    transport: :auto,  # :auto | :sse | :websocket | :graphql_ws
    enable_compression: false,
    chunk_timeout: 1_000,
    
    # Relay optimizations
    enable_relay_optimizations: true,
    connection_stream_batch_size: 20,
    
    # Error handling
    error_recovery_enabled: true,
    max_retry_attempts: 3,
    retry_delay_ms: 100,
    
    # Monitoring
    enable_telemetry: true,
    enable_logging: true,
    log_level: :debug
  }
  
  @type t :: %__MODULE__{
    enabled: boolean(),
    enable_defer: boolean(),
    enable_stream: boolean(),
    max_concurrent_streams: non_neg_integer(),
    max_stream_duration: non_neg_integer(),
    max_memory_mb: non_neg_integer(),
    max_pending_operations: non_neg_integer(),
    default_stream_batch_size: non_neg_integer(),
    max_stream_batch_size: non_neg_integer(),
    enable_dataloader_batching: boolean(),
    dataloader_timeout: non_neg_integer(),
    transport: atom(),
    enable_compression: boolean(),
    chunk_timeout: non_neg_integer(),
    enable_relay_optimizations: boolean(),
    connection_stream_batch_size: non_neg_integer(),
    error_recovery_enabled: boolean(),
    max_retry_attempts: non_neg_integer(),
    retry_delay_ms: non_neg_integer(),
    enable_telemetry: boolean(),
    enable_logging: boolean(),
    log_level: atom()
  }
  
  defstruct Map.keys(@default_config)
  
  @doc """
  Create a configuration from options.
  
  ## Examples
  
      iex> Config.from_options(enabled: true, max_concurrent_streams: 50)
      %Config{enabled: true, max_concurrent_streams: 50, ...}
  """
  @spec from_options(Keyword.t() | map()) :: t()
  def from_options(opts) when is_list(opts) do
    from_options(Enum.into(opts, %{}))
  end
  
  def from_options(opts) when is_map(opts) do
    config = Map.merge(@default_config, opts)
    struct(__MODULE__, config)
  end
  
  @doc """
  Load configuration from application environment.
  
  Reads configuration from `:absinthe, :incremental_delivery` in the application environment.
  """
  @spec from_env() :: t()
  def from_env do
    Application.get_env(:absinthe, :incremental_delivery, [])
    |> from_options()
  end
  
  @doc """
  Validate a configuration.
  
  Ensures all values are within acceptable ranges and compatible with each other.
  """
  @spec validate(t()) :: {:ok, t()} | {:error, list(String.t())}
  def validate(config) do
    errors = 
      []
      |> validate_transport(config)
      |> validate_limits(config)
      |> validate_timeouts(config)
      |> validate_features(config)
    
    if Enum.empty?(errors) do
      {:ok, config}
    else
      {:error, errors}
    end
  end
  
  @doc """
  Check if incremental delivery is enabled.
  """
  @spec enabled?(t()) :: boolean()
  def enabled?(%__MODULE__{enabled: enabled}), do: enabled
  def enabled?(_), do: false
  
  @doc """
  Check if defer is enabled.
  """
  @spec defer_enabled?(t()) :: boolean()
  def defer_enabled?(%__MODULE__{enabled: true, enable_defer: defer}), do: defer
  def defer_enabled?(_), do: false
  
  @doc """
  Check if stream is enabled.
  """
  @spec stream_enabled?(t()) :: boolean()
  def stream_enabled?(%__MODULE__{enabled: true, enable_stream: stream}), do: stream
  def stream_enabled?(_), do: false
  
  @doc """
  Get the appropriate transport module for the configuration.
  """
  @spec transport_module(t()) :: module()
  def transport_module(%__MODULE__{transport: transport}) do
    case transport do
      :auto -> detect_transport()
      :sse -> Absinthe.Incremental.Transport.SSE
      :websocket -> Absinthe.Incremental.Transport.WebSocket
      :graphql_ws -> Absinthe.GraphqlWS.Incremental.Transport
      module when is_atom(module) -> module
    end
  end
  
  @doc """
  Apply configuration to a blueprint.
  
  Adds the configuration to the blueprint's execution context.
  """
  @spec apply_to_blueprint(t(), Absinthe.Blueprint.t()) :: Absinthe.Blueprint.t()
  def apply_to_blueprint(config, blueprint) do
    put_in(
      blueprint.execution.context[:incremental_config],
      config
    )
  end
  
  @doc """
  Get configuration from a blueprint.
  """
  @spec from_blueprint(Absinthe.Blueprint.t()) :: t() | nil
  def from_blueprint(blueprint) do
    get_in(blueprint, [:execution, :context, :incremental_config])
  end
  
  @doc """
  Merge two configurations.
  
  The second configuration takes precedence.
  """
  @spec merge(t(), t() | Keyword.t() | map()) :: t()
  def merge(config1, config2) when is_struct(config2, __MODULE__) do
    Map.merge(config1, config2)
  end
  
  def merge(config1, opts) do
    config2 = from_options(opts)
    merge(config1, config2)
  end
  
  @doc """
  Get a specific configuration value.
  """
  @spec get(t(), atom(), any()) :: any()
  def get(config, key, default \\ nil) do
    Map.get(config, key, default)
  end
  
  # Private functions
  
  defp validate_transport(errors, %{transport: transport}) do
    valid_transports = [:auto, :sse, :websocket, :graphql_ws]
    
    if transport in valid_transports or is_atom(transport) do
      errors
    else
      ["Invalid transport: #{inspect(transport)}" | errors]
    end
  end
  
  defp validate_limits(errors, config) do
    errors
    |> validate_positive(:max_concurrent_streams, config)
    |> validate_positive(:max_memory_mb, config)
    |> validate_positive(:max_pending_operations, config)
    |> validate_positive(:default_stream_batch_size, config)
    |> validate_positive(:max_stream_batch_size, config)
    |> validate_batch_sizes(config)
  end
  
  defp validate_timeouts(errors, config) do
    errors
    |> validate_positive(:max_stream_duration, config)
    |> validate_positive(:dataloader_timeout, config)
    |> validate_positive(:chunk_timeout, config)
    |> validate_positive(:retry_delay_ms, config)
  end
  
  defp validate_features(errors, config) do
    cond do
      config.enabled and not (config.enable_defer or config.enable_stream) ->
        ["Incremental delivery enabled but both defer and stream are disabled" | errors]
      
      true ->
        errors
    end
  end
  
  defp validate_positive(errors, field, config) do
    value = Map.get(config, field)
    
    if is_integer(value) and value > 0 do
      errors
    else
      ["#{field} must be a positive integer, got: #{inspect(value)}" | errors]
    end
  end
  
  defp validate_batch_sizes(errors, config) do
    if config.default_stream_batch_size > config.max_stream_batch_size do
      ["default_stream_batch_size cannot exceed max_stream_batch_size" | errors]
    else
      errors
    end
  end
  
  defp detect_transport do
    # Auto-detect the best available transport
    cond do
      Code.ensure_loaded?(Absinthe.GraphqlWS.Incremental.Transport) ->
        Absinthe.GraphqlWS.Incremental.Transport
      
      Code.ensure_loaded?(Absinthe.Incremental.Transport.SSE) ->
        Absinthe.Incremental.Transport.SSE
      
      true ->
        Absinthe.Incremental.Transport.WebSocket
    end
  end
end