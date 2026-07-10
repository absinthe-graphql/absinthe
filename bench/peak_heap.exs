# Measures the TRUE peak process heap while running a query through Absinthe.
#
#   MIX_ENV=dev mix run bench/peak_heap.exs
#
# Peak is captured from `:garbage_collection` trace events on a dedicated worker
# process: GC fires when the heap fills, so the pre-GC block sizes are a faithful
# high-water mark that Benchee's allocation counter cannot see. Result term size
# (via term_to_binary) is reported as a proxy for the eventual JSON response size,
# so we can express peak as a multiple of payload.

Code.require_file("bench_schema.exs", __DIR__)

defmodule Absinthe.Bench.PeakHeap do
  @moduledoc false

  @wordsize :erlang.system_info(:wordsize)

  def measure(query, schema) do
    parent = self()

    worker =
      spawn(fn ->
        receive do
          :go -> :ok
        end

        {:ok, result} = Absinthe.run(query, schema)
        send(parent, {:result, byte_size(:erlang.term_to_binary(result))})

        receive do
          :stop -> :ok
        end
      end)

    :erlang.trace(worker, true, [:garbage_collection, {:tracer, self()}])
    send(worker, :go)

    peak_words = collect(worker, 0)

    result_bytes =
      receive do
        {:result, bytes} -> bytes
      after
        60_000 -> raise "worker timed out"
      end

    send(worker, :stop)
    :erlang.trace(worker, false, [:garbage_collection])

    %{peak_bytes: peak_words * @wordsize, result_bytes: result_bytes}
  end

  # Track the max of (young heap block + old heap block + heap fragments), in
  # words, across every GC start/end event until the worker reports its result.
  defp collect(worker, max) do
    receive do
      {:trace, ^worker, gc, info}
      when gc in [:gc_minor_start, :gc_minor_end, :gc_major_start, :gc_major_end] ->
        total =
          Keyword.get(info, :heap_block_size, 0) +
            Keyword.get(info, :old_heap_block_size, 0) +
            Keyword.get(info, :mbuf_size, 0)

        collect(worker, Kernel.max(max, total))
    after
      0 ->
        # Drain done for now; block briefly for more, but bail once the result
        # is in flight (the worker only sends :result after Absinthe.run returns).
        receive do
          {:trace, ^worker, gc, info}
          when gc in [:gc_minor_start, :gc_minor_end, :gc_major_start, :gc_major_end] ->
            total =
              Keyword.get(info, :heap_block_size, 0) +
                Keyword.get(info, :old_heap_block_size, 0) +
                Keyword.get(info, :mbuf_size, 0)

            collect(worker, Kernel.max(max, total))
        after
          200 -> max
        end
    end
  end

  def mb(bytes), do: Float.round(bytes / 1024 / 1024, 2)

  def run_all() do
    schema = Absinthe.Bench.Schema

    IO.puts("\n=== Peak process heap (worker), best of 3 ===\n")

    Enum.each(Absinthe.Bench.Queries.all(), fn {label, query} ->
      # Best-of-3: take the max peak (worst case) and min is noise; report max.
      runs = for _ <- 1..3, do: measure(query, schema)
      peak = runs |> Enum.map(& &1.peak_bytes) |> Enum.max()
      result = hd(runs).result_bytes
      ratio = if result > 0, do: Float.round(peak / result, 1), else: 0.0

      IO.puts(
        String.pad_trailing(label, 42) <>
          "peak=" <> String.pad_leading("#{mb(peak)} MB", 10) <>
          "  payload=" <> String.pad_leading("#{mb(result)} MB", 9) <>
          "  ratio=" <> "#{ratio}x"
      )
    end)

    IO.puts("")
  end
end

Absinthe.Bench.PeakHeap.run_all()
