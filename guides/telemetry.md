# Telemetry

Absinthe 1.5 uses `telemetry` to instrument its activity.

Call `:telemetry.attach/4` or `:telemetry.attach_many/4` to attach your
handler function to any of the following event names:

- `[:absinthe, :execute, :operation, :start]` when the operation starts
- `[:absinthe, :execute, :operation, :stop]` when the operation finishes
- `[:absinthe, :subscription, :publish, :start]` when a subscription starts
- `[:absinthe, :subscription, :publish, :stop]` when a subscription finishes
- `[:absinthe, :resolve, :field, :start]` when field resolution starts
- `[:absinthe, :resolve, :field, :stop]` when field resolution finishes

Telemetry handlers are called with `measurements` and `metadata`. For details on
what is passed, checkout `Absinthe.Phase.Telemetry`, `Absinthe.Middleware.Telemetry`,
and `Absinthe.Middleware.Batch`.

For async, batch, and dataloader fields, Absinthe sends the final event when
it gets the results. That might be later than when the results are ready. If
you need to know how long the underlying operation took, you'll need to hook
telemetry up to that underlying operation. See, for example, the recommended
telemetry events in the documentation for `Ecto.Repo`.

## Async Resolvers

  `Absinthe.Middleware.Async` exposes the following events:

  * `[:absinthe, :middleware, :async, :start]` - Dispatched before the
    async function is invoked. Does not run when `Task` is provided
    instead.

    * Measurement: `%{system_time: integer(), monotonic_time: integer()}`
    * Metadata:

      ```
      %{
        telemetry_span_context: term()
      }
      ```

  * `[:absinthe, :middleware, :async, :stop]` - Dispatched after the
    async function is invoked. Does not run when `Task` is provided
    instead.

    * Measurement: `%{duration: integer(), monotonic_time: integer()}`
    * Metadata:

      ```
      %{
        result: any(),
        telemetry_span_context: term()
      }
      ```

  * `[:absinthe, :middleware, :async, :exception]` - Dispatched when
    the async function encounters an exception. Does not run when `Task`
    is provided instead.

    * Measurement: `%{duration: integer(), monotonic_time: integer()}`
    * Metadata:

      ```
      %{
        kind: :throw | :error | :exit,
        reason: term(),
        stacktrace: list(),
        telemetry_span_context: term()
      }
      ```

## Batch Resolvers

  `Absinthe.Middleware.Batch` exposes the following events:

  * `[:absinthe, :middleware, :batch, :start]` - Dispatched before the
    provided batch function is invoked.

    * Measurement: `%{system_time: integer(), monotonic_time: integer()}`
    * Metadata:

      ```
      %{
        batch_fun: Absinthe.Middleware.Batch.batch_fun(),
        batch_opts: term(),
        batch_data: any(),
        telemetry_span_context: term()
      }
      ```

  * `[:absinthe, :middleware, :batch, :stop]` - Dispatched after the
    provided batch function is invoked.

    * Measurement: `%{duration: integer(), monotonic_time: integer()}`
    * Metadata:

      ```
      %{
        batch_fun: Absinthe.Middleware.Batch.batch_fun(),
        batch_opts: term(),
        batch_data: any(),
        result: any(),
        telemetry_span_context: term()
      }
      ```

  * `[:absinthe, :middleware, :batch, :exception]` - Dispatched when
    the provided batch function encounters an exception.

    * Measurement: `%{duration: integer(), monotonic_time: integer()}`
    * Metadata:

      ```
      %{
        batch_fun: Absinthe.Middleware.Batch.batch_fun(),
        batch_opts: term(),
        batch_data: any(),
        kind: :throw | :error | :exit,
        reason: term(),
        stacktrace: list(),
        telemetry_span_context: term()
      }
      ```

  * `[:absinthe, :middleware, :batch, :post, :start]` - Dispatched before
    the provided post batch function is invoked, used for field resolution.

    * Measurement: `%{system_time: integer(), monotonic_time: integer()}`
    * Metadata:

      ```
      %{
        resolution: Absinthe.Resolution.t(),
        post_batch_fun: Absinthe.Middleware.Batch.post_batch_fun(),
        batch_key: term(),
        batch_results: any(),
        telemetry_span_context: term()
      }
      ```

  * `[:absinthe, :middleware, :batch, :post, :stop]` - Dispatched after
    the provided post batch function is invoked, used for field resolution.

    * Measurement: `%{duration: integer(), monotonic_time: integer()}`
    * Metadata:

      ```
      %{
        result: any(),
        telemetry_span_context: term()
      }
      ```

  * `[:absinthe, :middleware, :batch, :post, :exception]` - Dispatched
    when the provided post batch function encounters an exception.

    * Measurement: `%{duration: integer(), monotonic_time: integer()}`
    * Metadata:

      ```
      %{
        kind: :throw | :error | :exit,
        reason: term(),
        stacktrace: list(),
        telemetry_span_context: term()
      }
      ```

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
