defmodule Absinthe.Streaming do
  @moduledoc """
  Unified streaming delivery for subscriptions and incremental delivery (@defer/@stream).

  This module provides a common foundation for delivering GraphQL results that are
  produced over time, whether through subscription updates or incremental delivery
  of deferred/streamed content.

  ## Overview

  Both subscriptions and incremental delivery share the pattern of delivering data
  in multiple payloads:

  - **Subscriptions**: Each mutation trigger produces a new result
  - **Incremental Delivery**: @defer/@stream directives split a single query into
    initial + incremental payloads

  This module consolidates the shared abstractions:

  - `Absinthe.Streaming.Executor` - Behaviour for pluggable task execution backends
  - `Absinthe.Streaming.TaskExecutor` - Default executor using Task.async_stream
  - `Absinthe.Streaming.Delivery` - Unified delivery for subscriptions with @defer/@stream

  ## Architecture

  ```
  Absinthe.Streaming
  ├── Executor      - Behaviour for custom execution backends (Oban, RabbitMQ, etc.)
  ├── TaskExecutor  - Default executor (Task.async_stream)
  └── Delivery      - Handles multi-payload delivery via pubsub
  ```

  ## Custom Executors

  The default executor uses `Task.async_stream` for in-process concurrent execution.
  You can implement `Absinthe.Streaming.Executor` to use alternative backends:

      defmodule MyApp.ObanExecutor do
        @behaviour Absinthe.Streaming.Executor

        @impl true
        def execute(tasks, opts) do
          # Queue tasks to Oban and stream results
          tasks
          |> Enum.map(&queue_to_oban/1)
          |> stream_results(opts)
        end
      end

  Configure at the schema level:

      defmodule MyApp.Schema do
        use Absinthe.Schema

        @streaming_executor MyApp.ObanExecutor

        # ... schema definition
      end

  Or per-request via context:

      Absinthe.run(query, MyApp.Schema,
        context: %{streaming_executor: MyApp.ObanExecutor}
      )

  See `Absinthe.Streaming.Executor` for full documentation.

  ## Usage

  For most use cases, you don't need to interact with this module directly.
  The subscription system automatically uses these abstractions when @defer/@stream
  directives are detected in subscription documents.
  """

  alias Absinthe.Blueprint

  @doc """
  Check if a blueprint has streaming tasks (deferred fragments or streamed fields).
  """
  @spec has_streaming_tasks?(Blueprint.t()) :: boolean()
  def has_streaming_tasks?(blueprint) do
    context = get_streaming_context(blueprint)

    has_deferred = not Enum.empty?(Map.get(context, :deferred_tasks, []))
    has_streamed = not Enum.empty?(Map.get(context, :stream_tasks, []))

    has_deferred or has_streamed
  end

  @doc """
  Get the streaming context from a blueprint.
  """
  @spec get_streaming_context(Blueprint.t()) :: map()
  def get_streaming_context(blueprint) do
    get_in(blueprint.execution.context, [:__streaming__]) || %{}
  end

  @doc """
  Get all streaming tasks from a blueprint.
  """
  @spec get_streaming_tasks(Blueprint.t()) :: list(map())
  def get_streaming_tasks(blueprint) do
    context = get_streaming_context(blueprint)

    deferred = Map.get(context, :deferred_tasks, [])
    streamed = Map.get(context, :stream_tasks, [])

    deferred ++ streamed
  end

  @doc """
  Check if a document source contains @defer or @stream directives.

  This is a quick check before running the full pipeline to determine
  if incremental delivery should be enabled.
  """
  @spec has_streaming_directives?(String.t() | Absinthe.Language.Source.t()) :: boolean()
  def has_streaming_directives?(source) when is_binary(source) do
    # Quick regex check - not perfect but catches most cases
    String.contains?(source, "@defer") or String.contains?(source, "@stream")
  end

  def has_streaming_directives?(%{body: body}) when is_binary(body) do
    has_streaming_directives?(body)
  end

  def has_streaming_directives?(_), do: false
end
