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
- `[:absinthe, :plugin, :before_resolution, :start]` when a plugin before_resolution callback starts
- `[:absinthe, :plugin, :before_resolution, :stop]` when a plugin before_resolution callback finishes
- `[:absinthe, :plugin, :after_resolution, :start]` when a plugin after_resolution callback starts
- `[:absinthe, :plugin, :after_resolution, :stop]` when a plugin after_resolution callback finishes

Telemetry handlers are called with `measurements` and `metadata`. For details on
what is passed, checkout `Absinthe.Phase.Telemetry`, `Absinthe.Middleware.Telemetry`,
and `Absinthe.Phase.Document.Execution.Resolution`.

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
