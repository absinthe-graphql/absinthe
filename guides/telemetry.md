# Telemetry

Absinthe 1.5 supports your use of `:telemetry` to instrument its activity.
Call `:telemetry.attach/4` or `:telemetry.attach_many/4` to attach your
handler function to any of the following event names:

- `[:absinthe, :execute, :operation, :start]` when the operation starts
- `[:absinthe, :execute, :operation, :stop]` when the operation finishes
- `[:absinthe, :subscription, :publish, :start]` when a subscription starts
- `[:absinthe, :subscription, :publish, :stop]` when a subscription finishes
- `[:absinthe, :resolve, :field, :start]` when field resolution starts
- `[:absinthe, :resolve, :field, :stop]` when field resolution finishes

For async, batch, and dataloader fields, Absinthe sends the final event when
it gets the results. That might be later than when the results are ready. If
you need to know how long the underlying operation took, you'll need to hook
telemetry up to that underlying operation. See, for example, the recommended
telemetry events in the documentation for `Ecto.Repo`.

Telemetry handles are called with `measurements` and `metadata`. For details on
what is passed, checkout `Absinthe.Phase.Telemetry` and `Absinthe.Middleware.Telemetry`

## Interactive Telemetry

If you've plugged Absinthe underneath Phoenix, you can watch resolution from
your `iex -S mix phx.server` prompt. Paste in:

```elixir
:telemetry.attach_many(
  :demo,
  [[:absinthe, :execute, :operation, :start], [:absinthe, :resolve, :field, :stop]],
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

Shortly after the log line for `POST /api/`, you'll see something like:

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

... and:

```elixir
telemetry: %{
  event_name: [:absinthe, :execute, :operation, :stop],
  measurements: %{duration: 158516000},
  metadata: %{
    blueprint: :...,
    id: -576460752303351647,
    start_time: 1565830447024372000
  }
}
```
