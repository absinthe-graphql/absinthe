# Total allocation (churn) per query via Benchee's memory measurement.
#
#   MIX_ENV=dev mix run bench/memory.exs
#
# Benchee's `memory_time` reports bytes ALLOCATED over the run (churn / GC
# pressure), which is distinct from the retained peak measured by peak_heap.exs.
# Both matter: churn drives how often GC runs; peak drives max_heap_size kills.

Code.require_file("bench_schema.exs", __DIR__)

schema = Absinthe.Bench.Schema

jobs =
  for {label, query} <- Absinthe.Bench.Queries.all(), into: %{} do
    {label, fn -> Absinthe.run(query, schema) end}
  end

Benchee.run(
  jobs,
  time: 3,
  memory_time: 2,
  warmup: 1,
  print: [fast_warning: false]
)
