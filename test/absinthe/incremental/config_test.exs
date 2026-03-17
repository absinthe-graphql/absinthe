defmodule Absinthe.Incremental.ConfigTest do
  @moduledoc """
  Tests for Absinthe.Incremental.Config module.
  """

  use ExUnit.Case, async: true

  alias Absinthe.Incremental.Config

  describe "from_options/1" do
    test "creates config with default values" do
      config = Config.from_options([])
      assert config.enabled == false
      assert config.enable_defer == true
      assert config.enable_stream == true
      assert config.on_event == nil
    end

    test "accepts on_event callback" do
      callback = fn _type, _payload, _meta -> :ok end
      config = Config.from_options(on_event: callback)
      assert config.on_event == callback
    end

    test "accepts custom options" do
      config =
        Config.from_options(
          enabled: true,
          max_concurrent_streams: 50,
          on_event: fn _, _, _ -> :ok end
        )

      assert config.enabled == true
      assert config.max_concurrent_streams == 50
      assert is_function(config.on_event, 3)
    end
  end

  describe "emit_event/4" do
    test "does nothing when config is nil" do
      assert :ok == Config.emit_event(nil, :initial, %{}, %{})
    end

    test "does nothing when on_event is nil" do
      config = Config.from_options([])
      assert :ok == Config.emit_event(config, :initial, %{}, %{})
    end

    test "calls on_event callback with event type, payload, and metadata" do
      test_pid = self()

      callback = fn event_type, payload, metadata ->
        send(test_pid, {:event, event_type, payload, metadata})
      end

      config = Config.from_options(on_event: callback)

      Config.emit_event(config, :initial, %{data: "test"}, %{operation_id: "abc123"})

      assert_receive {:event, :initial, %{data: "test"}, %{operation_id: "abc123"}}
    end

    test "handles all event types" do
      test_pid = self()
      callback = fn type, _, _ -> send(test_pid, {:type, type}) end
      config = Config.from_options(on_event: callback)

      Config.emit_event(config, :initial, %{}, %{})
      Config.emit_event(config, :incremental, %{}, %{})
      Config.emit_event(config, :complete, %{}, %{})
      Config.emit_event(config, :error, %{}, %{})

      assert_receive {:type, :initial}
      assert_receive {:type, :incremental}
      assert_receive {:type, :complete}
      assert_receive {:type, :error}
    end

    test "catches errors in callback and returns :ok" do
      callback = fn _, _, _ -> raise "intentional error" end
      config = Config.from_options(on_event: callback)

      # Should not raise, should return :ok
      assert :ok == Config.emit_event(config, :error, %{}, %{})
    end

    test "ignores non-function on_event values" do
      # Manually create a config with invalid on_event
      config = %Config{
        enabled: true,
        enable_defer: true,
        enable_stream: true,
        max_concurrent_streams: 100,
        max_stream_duration: 30_000,
        max_memory_mb: 500,
        max_pending_operations: 1000,
        default_stream_batch_size: 10,
        max_stream_batch_size: 100,
        enable_dataloader_batching: true,
        dataloader_timeout: 5_000,
        transport: :auto,
        enable_compression: false,
        chunk_timeout: 1_000,
        enable_relay_optimizations: true,
        connection_stream_batch_size: 20,
        error_recovery_enabled: true,
        max_retry_attempts: 3,
        retry_delay_ms: 100,
        enable_telemetry: true,
        enable_logging: true,
        log_level: :debug,
        on_event: "not a function"
      }

      assert :ok == Config.emit_event(config, :initial, %{}, %{})
    end
  end

  describe "validate/1" do
    test "validates a valid config" do
      config = Config.from_options(enabled: true)
      assert {:ok, ^config} = Config.validate(config)
    end

    test "returns errors for invalid transport" do
      config = Config.from_options(transport: 123)
      assert {:error, errors} = Config.validate(config)
      assert Enum.any?(errors, &String.contains?(&1, "transport"))
    end
  end

  describe "enabled?/1" do
    test "returns false when not enabled" do
      config = Config.from_options(enabled: false)
      refute Config.enabled?(config)
    end

    test "returns true when enabled" do
      config = Config.from_options(enabled: true)
      assert Config.enabled?(config)
    end
  end
end
