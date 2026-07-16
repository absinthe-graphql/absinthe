# Shared schema, data, and pipeline helpers for the memory benchmarks
# (memory_footprint.exs and memory_peak.exs), written for issue #1245 (large
# list results using far more RAM than the response size).
#
# The two runner scripts measure different things, and both matter:
#
#   * memory_footprint.exs — total bytes ALLOCATED per run (churn), via
#     Benchee. Churn drives how often GC runs, i.e. CPU cost and latency.
#   * memory_peak.exs — the high-water mark of memory reserved for the
#     process. The peak is what `:max_heap_size` kills and OOM care about.
#
# Churn is usually the larger number, but a (nearly) zero-garbage run can push
# it below the peak: allocation approaches the size of the retained result,
# while the peak still includes BEAM heap-block overhead — blocks grow on a
# fixed stage schedule, and a copying GC where everything survives briefly
# needs from-space and to-space at once. E.g. 100k nullable strings allocate
# ~1.53 MB (exactly the result list's cons cells; the strings themselves are
# literal-area references) while peaking at ~2.45 MB of heap capacity.
#
# Source data is generated once and stashed in :persistent_term (reads are not
# copied) and the telemetry phase is excluded from the measured pipeline, so
# measurements cover resolution + result construction only.
#
# Scenarios:
#
#   * 20k objects / 40k leaves — `{ things { a b } }` over 20,000 objects,
#     each with two string fields.
#   * 100k strings [String] — `list_of(:string)` with 100,000 elements
#     (compact LeafList representation).
#   * 100k strings [String!] — same data as `list_of(non_null(:string))`,
#     which keeps the per-element Result.Leaf representation.

defmodule MemBench.Schema do
  use Absinthe.Schema

  object :thing do
    field :a, :string
    field :b, :string
  end

  query do
    field :things, list_of(:thing) do
      resolve fn _, _, _ -> {:ok, :persistent_term.get({MemBench, :things})} end
    end

    field :strings, list_of(:string) do
      resolve fn _, _, _ -> {:ok, :persistent_term.get({MemBench, :strings})} end
    end

    field :strings_non_null, list_of(non_null(:string)) do
      resolve fn _, _, _ -> {:ok, :persistent_term.get({MemBench, :strings})} end
    end
  end
end

defmodule MemBench do
  alias Absinthe.{Pipeline, Phase}

  @resolution_phase Phase.Document.Execution.Resolution

  @things_count 20_000
  @strings_count 100_000

  def seed_data() do
    things = for i <- 1..@things_count, do: %{a: "aaaa-#{i}", b: "bbbb-#{i}"}
    strings = for i <- 1..@strings_count, do: "string-#{i}"

    :persistent_term.put({MemBench, :things}, things)
    :persistent_term.put({MemBench, :strings}, strings)
  end

  def prepare(query) do
    pipeline = Pipeline.for_document(MemBench.Schema, [])
    {:ok, bp, _} = Pipeline.run(query, Pipeline.before(pipeline, @resolution_phase))
    bp
  end

  def resolution_tail() do
    MemBench.Schema
    |> Pipeline.for_document([])
    |> Pipeline.from(@resolution_phase)
    |> Pipeline.without(Phase.Telemetry)
  end

  def resolve(bp, tail) do
    {:ok, bp, _} = Pipeline.run(bp, tail)
    bp.result
  end

  def sanity_check!(bp_things, bp_strings, bp_strings_nn, tail) do
    %{data: %{"things" => things}} = result = resolve(bp_things, tail)

    unless length(things) == @things_count and not Map.has_key?(result, :errors) do
      raise "sanity check failed for things: #{inspect(Map.delete(result, :data))}"
    end

    unless %{"a" => "aaaa-1", "b" => "bbbb-1"} == hd(things) do
      raise "sanity check failed for things content: #{inspect(hd(things))}"
    end

    %{data: %{"strings" => strings}} = result = resolve(bp_strings, tail)

    unless length(strings) == @strings_count and not Map.has_key?(result, :errors) do
      raise "sanity check failed for strings: #{inspect(Map.delete(result, :data))}"
    end

    unless hd(strings) == "string-1" do
      raise "sanity check failed for strings content: #{inspect(hd(strings))}"
    end

    %{data: %{"stringsNonNull" => strings_nn}} = result = resolve(bp_strings_nn, tail)

    unless length(strings_nn) == @strings_count and not Map.has_key?(result, :errors) do
      raise "sanity check failed for stringsNonNull: #{inspect(Map.delete(result, :data))}"
    end

    unless hd(strings_nn) == "string-1" do
      raise "sanity check failed for stringsNonNull content: #{inspect(hd(strings_nn))}"
    end

    IO.puts("sanity checks passed\n")
  end
end
