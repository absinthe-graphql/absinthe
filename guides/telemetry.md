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

By default, only fields with a resolver get measured. You can override this
by setting `absinthe_telemetry` in its metadata to `true` or `false` with
`Absinthe.Schema.Notation.meta/1`.

For async, batch, and dataloader fields, Absinthe sends the final event when
it gets the results. That might be later than when the results are ready. If
you need to know how long the underlying operation took, you'll need to hook
telemetry up to that underlying operation. See, for example, the recommended
telemetry events in the documentaiton for `Ecto.Repo`.

## Measurements

Absinthe passes the following measurements in the second argument to your
handler function:

- `start_time` with event names ending with `:start`
- `duration` with event names ending with `:stop`

## Metadata

Absinthe passes the following measurements in the third argument to your
handler function:

- `id` (`t:integer/0` from `:erlang.unique_integer/0`) with all event names
- `start_time` (`t:pos_integer/0` from `System.system_time/0`) with event names not ending with `:start`
- `middleware` (a list of `t:Absinthe.Middleware.spec/0`) with `[:absinthe, :resolve, :field]`
- `resolution` (`t:Absinthe.Resolution.t/0`) with `[:absinthe, :resolve, :field]`
- `blueprint` (`t:Absinthe.Blueprint.t/0`) with `[:absinthe, :execute, :operation]` and `[absinthe, :subscription, :publish]`
- `options` (`t:keyword/0`) with `[:absinthe, :execute, :operation]`

## Interactive Telemetry

If you've plugged Absinthe underneath Phoenix, you can watch resolution from
your `iex -S mix phx.server` prompt. Paste in:

```elixir
:telemetry.attach_many(
  :demo,
  [[:absinthe, :execute, :operation, :stop], [:absinthe, :resolve, :field, :stop]],
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
  event_name: [:absinthe, :execute, :operation, :stop],
  measurements: %{duration: 158516000},
  metadata: %{
    blueprint: :...,
    id: -576460752303351647,
    start_time: 1565830447024372000
  }
}
```
