# Demonstrates the cost of re-walking the result tree when fields suspend.
#
# Run with:
#
#     mix run benchmarks/resolution_rewalk.exs
#
# The resolution phase re-runs once per "round" of suspension (batch, async,
# dataloader). Each re-run walks the *entire* result tree — including subtrees
# that fully resolved in an earlier pass — just to locate the suspended fields.
#
# Scenarios (per input size N):
#
#   * sync      — `{ items(count: N) { a b c d } }`
#                 Everything resolves synchronously. 1 resolution pass.
#                 This is the baseline cost of walking/building the tree once.
#
#   * batch_leaf — `{ items(count: N) { a b c d batched } }`
#                 The classic N+1 pattern: every item has one batched field.
#                 2 passes; the second pass re-walks all N items.
#
#   * chain_4 / chain_24 — `{ items(count: N) { a b c d } chain { next { ... } } }`
#                 A single chain of K nested batched fields *next to* the wide
#                 sync tree. Each chain level forces a full extra resolution
#                 pass, so K levels = K+1 passes. The chain itself adds a
#                 constant, trivial amount of real work (K batches of size 1),
#                 so any time growth over `sync` is pure re-walk overhead.
#
# If re-walking were free, chain_24 would cost roughly sync + 24 tiny batch
# lookups. Instead it costs roughly 25 × sync.

defmodule Rewalk.Schema do
  use Absinthe.Schema

  import Absinthe.Resolution.Helpers, only: [batch: 3]

  object :item do
    field :a, :string
    field :b, :string
    field :c, :string
    field :d, :string

    field :batched, :string do
      resolve fn item, _, _ ->
        batch({__MODULE__, :lookup}, item.id, fn results ->
          {:ok, Map.get(results, item.id)}
        end)
      end
    end
  end

  object :chain_node do
    field :depth, :integer

    field :next, :chain_node do
      resolve fn node, _, _ ->
        batch({__MODULE__, :next_node}, node.depth, fn results ->
          {:ok, Map.get(results, node.depth)}
        end)
      end
    end
  end

  query do
    field :items, list_of(:item) do
      arg :count, non_null(:integer)

      resolve fn _, %{count: count}, _ ->
        items = for i <- 1..count, do: %{id: i, a: "a", b: "b", c: "c", d: "d"}
        {:ok, items}
      end
    end

    field :chain, :chain_node do
      resolve fn _, _, _ -> {:ok, %{depth: 0}} end
    end
  end

  def lookup(_, ids), do: Map.new(ids, &{&1, "batched-#{&1}"})

  def next_node(_, depths), do: Map.new(depths, &{&1, %{depth: &1 + 1}})
end

defmodule Rewalk.Bench do
  alias Absinthe.{Pipeline, Phase}

  @resolution_phase Phase.Document.Execution.Resolution

  def queries(count) do
    %{
      sync: "{ items(count: #{count}) { a b c d } }",
      batch_leaf: "{ items(count: #{count}) { a b c d batched } }",
      chain_4: "{ items(count: #{count}) { a b c d } chain { #{chain(4)} } }",
      chain_24: "{ items(count: #{count}) { a b c d } chain { #{chain(24)} } }"
    }
  end

  defp chain(0), do: "depth"
  defp chain(k), do: "depth next { #{chain(k - 1)} }"

  # Run the pipeline up to (but not including) the resolution phase, so
  # benchmark iterations measure only resolution + result construction.
  def prepare(query) do
    pipeline = Pipeline.for_document(Rewalk.Schema, [])
    {:ok, bp, _} = Pipeline.run(query, Pipeline.before(pipeline, @resolution_phase))
    bp
  end

  def resolution_tail do
    Rewalk.Schema
    |> Pipeline.for_document([])
    |> Pipeline.from(@resolution_phase)
  end

  def resolve(bp, tail) do
    {:ok, bp, _} = Pipeline.run(bp, tail)
    bp.result
  end

  def sanity_check! do
    tail = resolution_tail()

    for {name, query} <- queries(3) do
      result = resolve(prepare(query), tail)

      unless match?(%{data: %{}}, result) and not Map.has_key?(result, :errors) do
        raise "sanity check failed for #{name}: #{inspect(result)}"
      end
    end

    # Verify the chain actually resolves to full depth.
    %{data: data} = resolve(prepare(queries(3).chain_24), tail)
    depth = depth_of(data["chain"])

    unless depth == 25 do
      raise "expected chain depth 25, got #{depth}"
    end

    IO.puts("sanity checks passed\n")
  end

  defp depth_of(%{"next" => next}), do: 1 + depth_of(next)
  defp depth_of(_), do: 1
end

Rewalk.Bench.sanity_check!()

tail = Rewalk.Bench.resolution_tail()

inputs =
  for count <- [100, 1_000, 10_000], into: %{} do
    prepared =
      Map.new(Rewalk.Bench.queries(count), fn {name, q} -> {name, Rewalk.Bench.prepare(q)} end)

    {"#{count} items", prepared}
  end

Benchee.run(
  %{
    "sync (1 pass)" => fn %{sync: bp} -> Rewalk.Bench.resolve(bp, tail) end,
    "batch_leaf (2 passes)" => fn %{batch_leaf: bp} -> Rewalk.Bench.resolve(bp, tail) end,
    "chain_4 (5 passes)" => fn %{chain_4: bp} -> Rewalk.Bench.resolve(bp, tail) end,
    "chain_24 (25 passes)" => fn %{chain_24: bp} -> Rewalk.Bench.resolve(bp, tail) end
  },
  inputs: inputs,
  warmup: 1,
  time: 3,
  memory_time: 1
)
