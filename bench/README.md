# Memory benchmarks

Benchmarks for the memory footprint of query execution, originally written for
[#1245](https://github.com/absinthe-graphql/absinthe/issues/1245) (large list
results using far more RAM than the response size).

## Running

Benchee is a `:dev`-only dependency, so run these under `MIX_ENV=dev`:

```sh
# Peak process heap (what trips :max_heap_size). Best of 3 per query.
MIX_ENV=dev mix run bench/peak_heap.exs

# Total bytes allocated per request (churn / GC pressure), via Benchee.
MIX_ENV=dev mix run bench/memory.exs
```

Both scripts load `bench/bench_schema.exs`, which defines a small in-memory
schema (no database, no custom types) with four queries: a large nested-object
list (the #1245 shape), the same with a non-null element type, a flat list of
100k strings, and a tiny control query. Query shapes and sizes live in
`bench/bench_schema.exs` if you want to tweak them.

## What they measure

The two scripts measure different things, and both matter:

- **`peak_heap.exs`** runs the query in a dedicated process and tracks the
  high-water mark of its heap from `:garbage_collection` trace events. This is
  the number behind `max_heap_size` kills — the retained peak, which Benchee's
  allocation counter can't see.
- **`memory.exs`** reports total bytes *allocated* over the run (churn). This
  drives how often GC runs and CPU cost, but not the peak.

"Payload" in the peak output is `byte_size(:erlang.term_to_binary(result))`, a
rough proxy for the JSON response size (term_to_binary runs larger than JSON, so
the reported multiples are conservative).

## Reference numbers

Measured locally (Elixir 1.21-dev / OTP 27), comparing `main` against the
list-memory changes on this branch. Your absolute numbers will vary by machine;
the ratios are the point.

### Peak process heap

| Query | Before | After |
|-------|--------|-------|
| list of 20k nested objects (#1245 repro) | 31.26 MB (34.5×) | 11.58 MB (12.8×) — **−63%** |
| list of 20k objects, non-null elements | 26.70 MB | 9.13 MB — **−66%** |
| list of 100k strings | 24.97 MB (16.5×) | 2.44 MB (1.6×) — **−90%** |
| tiny query (control) | 0.02 MB | 0.02 MB |

(× = multiple of payload size.)

### Total allocation per request

| Query | Before | After |
|-------|--------|-------|
| list of 20k nested objects | 77.34 MB | 64.49 MB — **−17%** |
| list of 100k strings | 44.07 MB | 1.61 MB — **−96%** |
