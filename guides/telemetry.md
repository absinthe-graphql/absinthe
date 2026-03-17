# Telemetry

Absinthe 1.5 and up uses `telemetry` to instrument its activity.

Call `:telemetry.attach/4` or `:telemetry.attach_many/4` to attach your
handler function to any of the following event names:

- `[:absinthe, :execute, :operation, :start]` when the operation starts
- `[:absinthe, :execute, :operation, :stop]` when the operation finishes
- `[:absinthe, :subscription, :publish, :start]` when a subscription starts
- `[:absinthe, :subscription, :publish, :stop]` when a subscription finishes
- `[:absinthe, :resolve, :field, :start]` when field resolution starts
- `[:absinthe, :resolve, :field, :stop]` when field resolution finishes
- `[:absinthe, :middleware, :batch, :start]` when the batch processing starts
- `[:absinthe, :middleware, :batch, :stop]` when the batch processing finishes
- `[:absinthe, :middleware, :batch, :timeout]` when the batch processing times out

### Incremental Delivery Events (@defer/@stream)

When using `@defer` or `@stream` directives, additional events are emitted:

- `[:absinthe, :incremental, :start]` when incremental delivery begins
- `[:absinthe, :incremental, :stop]` when incremental delivery ends
- `[:absinthe, :incremental, :delivery, :initial]` when the initial response is sent
- `[:absinthe, :incremental, :delivery, :payload]` when each deferred/streamed payload is delivered
- `[:absinthe, :incremental, :delivery, :complete]` when all payloads have been delivered
- `[:absinthe, :incremental, :delivery, :error]` when an error occurs during streaming

Telemetry handlers are called with `measurements` and `metadata`. For details on
what is passed, checkout `Absinthe.Phase.Telemetry`, `Absinthe.Middleware.Telemetry`,
`Absinthe.Middleware.Batch`, and `Absinthe.Incremental.Transport`.

For async, batch, and dataloader fields, Absinthe sends the final event when
it gets the results. That might be later than when the results are ready. If
you need to know how long the underlying operation took, you'll need to hook
telemetry up to that underlying operation. See, for example, the recommended
telemetry events in the documentation for `Ecto.Repo`.

## Interactive Telemetry

As an example, you could attach a handler in an `iex -S mix` shell. Paste in:

```elixir
:telemetry.attach_many(
  :demo,
  [
    [:absinthe, :resolve, :field, :stop]
  ],
  fn event_name, measurements, metadata, _config ->
    %{
      event_name: event_name,
      measurements: measurements,
      metadata: metadata
    }
    |> IO.inspect()
  end,
  []
)
```

After a query is executed, you'll see something like:

```elixir
%{
  event_name: [:absinthe, :resolve, :field, :stop],
  measurements: %{duration: 14000},
  metadata: %{
    id: -576460752303351647,
    middleware: [
      {{Absinthe.Resolution, :call}, &MyApp.Resolvers.resolve_field/3}
    ],
    resolution: :...,
    start_time: 1565830447035742000
  }
}
```

## Opentelemetry

When using Opentelemetry, one usually wants to correlate spans that are created
in spawned tasks with the main trace. For example, you might have a trace started
in a Phoenix endpoint, and then have spans around database access.

One can correlate manually by attaching the OTel context the task function:

```elixir
ctx = OpenTelemetry.Ctx.get_current()

Task.async(fn ->
  OpenTelemetry.Ctx.attach(ctx)

  # do stuff that might create spans
end)
```

When using the `async` and `batch` middleware, the tasks are spawned by Absinthe,
so you can't attach the context manually.

Instead, you can add the `:opentelemetry_process_propagator` package to your
dependencies, which has a `Task.async/1` wrapper that will attach the context
automatically. If the package is installed, the middleware will use it in place
of the default `Task.async/1`.

## Incremental Delivery Telemetry Details

The incremental delivery events provide detailed information for tracing `@defer` and
`@stream` operations. All delivery events include an `operation_id` for correlating
events within the same operation.

### `[:absinthe, :incremental, :delivery, :initial]`

Emitted when the initial response (with `hasNext: true`) is sent to the client.

**Measurements:**
- `system_time` - System time when the event occurred

**Metadata:**
- `operation_id` - Unique identifier for correlating events
- `has_next` - Always `true` for initial response
- `pending_count` - Number of pending deferred/streamed operations
- `response` - The initial response payload

### `[:absinthe, :incremental, :delivery, :payload]`

Emitted for each `@defer` or `@stream` payload delivered to the client.

**Measurements:**
- `system_time` - System time when the event occurred
- `duration` - Time to execute this specific deferred/streamed task (native time units)

**Metadata:**
- `operation_id` - Unique identifier for correlating events
- `path` - GraphQL path to the deferred/streamed field (e.g., `["user", "profile"]`)
- `label` - Label from the directive (e.g., `@defer(label: "userProfile")`)
- `task_type` - Either `:defer` or `:stream`
- `has_next` - Whether more payloads are expected
- `duration_ms` - Duration in milliseconds
- `success` - Whether the task completed successfully
- `response` - The incremental response payload

### `[:absinthe, :incremental, :delivery, :complete]`

Emitted when all payloads have been delivered successfully.

**Measurements:**
- `system_time` - System time when the event occurred
- `duration` - Total duration of the incremental delivery (native time units)

**Metadata:**
- `operation_id` - Unique identifier for correlating events
- `duration_ms` - Total duration in milliseconds

### `[:absinthe, :incremental, :delivery, :error]`

Emitted when an error occurs during incremental delivery.

**Measurements:**
- `system_time` - System time when the event occurred
- `duration` - Duration until the error occurred (native time units)

**Metadata:**
- `operation_id` - Unique identifier for correlating events
- `duration_ms` - Duration in milliseconds
- `error` - Map with `:reason` and `:message` keys

### Example: Tracing Incremental Delivery

```elixir
:telemetry.attach_many(
  :incremental_delivery_tracer,
  [
    [:absinthe, :incremental, :delivery, :initial],
    [:absinthe, :incremental, :delivery, :payload],
    [:absinthe, :incremental, :delivery, :complete],
    [:absinthe, :incremental, :delivery, :error]
  ],
  fn event_name, measurements, metadata, _config ->
    IO.inspect({event_name, metadata.operation_id, measurements})
  end,
  []
)
```

### Custom Event Callbacks

In addition to telemetry events, you can pass an `on_event` callback option for
custom monitoring integrations (e.g., Sentry, DataDog):

```elixir
Absinthe.run(query, schema,
  on_event: fn
    :error, payload, metadata ->
      Sentry.capture_message("GraphQL streaming error",
        extra: %{payload: payload, metadata: metadata}
      )
    :incremental, _payload, %{duration_ms: ms} when ms > 1000 ->
      Logger.warning("Slow @defer/@stream operation: #{ms}ms")
    _, _, _ -> :ok
  end
)
```

Event types for `on_event`: `:initial`, `:incremental`, `:complete`, `:error`
