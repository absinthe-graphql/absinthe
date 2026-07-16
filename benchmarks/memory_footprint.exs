# Total allocation (churn) per query, via Benchee's memory measurement.
#
#     mix run benchmarks/memory_footprint.exs
#
# See benchmarks/support/mem_bench.exs for the shared schema/scenarios and for
# how churn relates to the peak measured by memory_peak.exs.

Code.require_file("support/mem_bench.exs", __DIR__)

MemBench.seed_data()

tail = MemBench.resolution_tail()
bp_things = MemBench.prepare("{ things { a b } }")
bp_strings = MemBench.prepare("{ strings }")
bp_strings_nn = MemBench.prepare("{ stringsNonNull }")

MemBench.sanity_check!(bp_things, bp_strings, bp_strings_nn, tail)

# Benchee's comparison section relates every job in a run, which only makes
# sense for jobs over the same workload: the two strings scenarios resolve
# identical data (nullable vs non-null element type). The objects scenario is
# a different workload, reported separately as absolute numbers.
Benchee.run(
  %{
    "100k strings [String]" => fn -> MemBench.resolve(bp_strings, tail) end,
    "100k strings [String!]" => fn -> MemBench.resolve(bp_strings_nn, tail) end
  },
  warmup: 1,
  time: 2,
  memory_time: 2
)

Benchee.run(
  %{"20k objects / 40k leaves" => fn -> MemBench.resolve(bp_things, tail) end},
  warmup: 1,
  time: 2,
  memory_time: 2
)
