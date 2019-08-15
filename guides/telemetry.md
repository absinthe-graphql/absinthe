# Telemetry

Absinthe 1.5 supports your use of `:telemetry` to instrument its activity.
Call `:telemetry.attach/4` or `:telemetry.attach_many/4` to attach your
handler function to any of the following event names:

- `[:absinthe, :execute, :operation, :start]` when the operation starts
- `[:absinthe, :execute, :operation]` when the operation finishes
- `[:absinthe, :subscription, :publish, :start]` when a subscription starts
- `[:absinthe, :subscription, :publish]` when a subscription finishes
- `[:absinthe, :resolve, :field, :start]` when field resolution starts
- `[:absinthe, :resolve, :field]` when field resolution finishes

By default, only fields with a resolver get measured. You can override this
by setting `absinthe_telemetry` in its metadata to `true` or `false` with
`Absinthe.Schema.Notation.meta/1`.

For async, batch, and dataloader fields, Absinthe sends the final event when
it gets the results. That might be later than when the results are ready. If
you need to know how long the underlying operation took, you'll need to hook
telemetry up to that underlying operation. See, for example, the recommended
telemetry events in the documentaiton for `Ecto.Repo`.

## Measurements

- `start_time`: sent with event names ending with `:start`
- `duration`: sent with event names not ending with `:start`

## Metadata

- `id`: sent with all event names
- `start_time`: sent with event names not ending with `:start`
- `middleware`: sent with `[:absinthe, :resolve, :field]`
- `resolution`: sent with `[:absinthe, :resolve, :field]`
- `blueprint`: sent with `[:absinthe, :execute, :operation]`
- `options`: sent with `[:absinthe, :execute, :operation]`

## Interactive Telemetry

If you've plugged Absinthe underneath Phoenix, you can watch resolution from
your `iex -S mix phx.server` prompt. Paste in:

```elixir
:telemetry.attach_many(
  :demo,
  [[:absinthe, :execute, :operation], [:absinthe, :resolve, :field]],
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
  event_name: [:absinthe, :resolve, :field],
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
  event_name: [:absinthe, :execute, :operation],
  measurements: %{duration: 158516000},
  metadata: %{
    blueprint: :...,
    id: -576460752303351647,
    start_time: 1565830447024372000
  }
}
```
