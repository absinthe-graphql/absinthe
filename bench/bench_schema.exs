# Shared schema + data generator for the memory benchmarks (issue #1245).
#
# Loaded via `Code.require_file/1` from the runner scripts (bench/peak_heap.exs,
# bench/memory.exs). Uses only built-in scalars, so it has no dependency on
# :decimal / custom types.

defmodule Absinthe.Bench.Data do
  @moduledoc false

  # Reproduces the shape from https://github.com/IvanIvanoff/absinthe_memory:
  # `points` timeseries entries, each with `assets` nested {asset, value} rows.
  # Defaults match the issue: 200 x 100 = 20k objects, ~40k scalar leaves.
  def nested_objects(points \\ 200, assets \\ 100) do
    asset_names = for i <- 1..assets, do: "asset_" <> Integer.to_string(i)

    for i <- 1..points do
      data =
        for name <- asset_names do
          %{asset: name, value: i * 1.0 + byte_size(name)}
        end

      %{datetime: "2026-01-01T00:#{rem(i, 60)}:00Z", data: data}
    end
  end

  def strings(n \\ 100_000) do
    for i <- 1..n, do: "value_" <> Integer.to_string(i)
  end
end

defmodule Absinthe.Bench.Schema do
  @moduledoc false
  use Absinthe.Schema

  @nested Absinthe.Bench.Data.nested_objects()
  @strings Absinthe.Bench.Data.strings()

  object :asset_data do
    field(:asset, :string)
    field(:value, :float)
  end

  object :timeseries_point do
    field(:datetime, :string)
    field(:data, list_of(:asset_data))
  end

  object :metric do
    field :timeseries_data_per_asset, list_of(:timeseries_point) do
      resolve(fn _, _, _ -> {:ok, @nested} end)
    end
  end

  # Same shape but with a non-null element type, to exercise the [T!] path.
  object :non_null_metric do
    field :timeseries_data_per_asset, list_of(non_null(:timeseries_point)) do
      resolve(fn _, _, _ -> {:ok, @nested} end)
    end
  end

  query do
    # A big list of nested objects (200 x 100 = 20k objects, ~40k scalar fields).
    # This is the issue #1245 reproduction.
    field :object_list, :metric do
      resolve(fn _, _, _ -> {:ok, %{}} end)
    end

    # Same, but the list has a non-null element type ([T!]).
    field :non_null_object_list, :non_null_metric do
      resolve(fn _, _, _ -> {:ok, %{}} end)
    end

    # A flat list of 100k scalars.
    field :string_list, list_of(:string) do
      resolve(fn _, _, _ -> {:ok, @strings} end)
    end

    # A tiny, non-list query — a control to catch any CPU/allocation regression
    # on the common small-response case.
    field :sentinel, :string do
      resolve(fn _, _, _ -> {:ok, "ok"} end)
    end
  end
end

defmodule Absinthe.Bench.Queries do
  @moduledoc false

  # {label, query} pairs shared by both runner scripts.
  def all() do
    [
      {"list of 20k nested objects (#1245 repro)",
       "{ objectList { timeseriesDataPerAsset { datetime data { asset value } } } }"},
      {"list of 20k objects, non-null elements",
       "{ nonNullObjectList { timeseriesDataPerAsset { datetime data { asset value } } } }"},
      {"list of 100k strings", "{ stringList }"},
      {"tiny query (control)", "{ sentinel }"}
    ]
  end
end
