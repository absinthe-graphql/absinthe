# Peak process memory during resolution of large result sets.
#
#     mix run benchmarks/memory_peak.exs
#
# Each scenario runs in a fresh process; a sampler polls
# `:erlang.process_info(pid, :memory)` in a tight loop and records the peak.
# See benchmarks/support/mem_bench.exs for the shared schema/scenarios and for
# how the peak relates to the allocation churn measured by
# memory_footprint.exs.
#
# "payload" is `byte_size(:erlang.term_to_binary(result))`, a rough proxy for
# the JSON response size; "ratio" is peak/payload — how much memory it takes
# to produce one byte of response.

Code.require_file("support/mem_bench.exs", __DIR__)

defmodule MemBench.Peak do
  # Runs `fun` in a fresh process and returns its peak memory and result size.
  def measure(fun) do
    parent = self()

    {pid, ref} =
      spawn_monitor(fn ->
        receive do
          :go -> :ok
        end

        result = fun.()
        # term_to_binary runs a bit larger than JSON, so payload ratios are
        # conservative. It also keeps the result alive so the peak includes
        # it, without skewing the measurement: the binary is refc (off-heap),
        # whereas e.g. :erts_debug.size/1 would build a sharing-tracking set
        # on this process's heap and inflate the peak ~10x for large lists.
        send(parent, {:result_size, byte_size(:erlang.term_to_binary(result))})
      end)

    sampler =
      spawn(fn ->
        send(parent, {:peak, sample_loop(pid, 0)})
      end)

    send(pid, :go)

    peak =
      receive do
        {:peak, peak} -> peak
      end

    receive do
      {:DOWN, ^ref, :process, ^pid, :normal} -> :ok
      {:DOWN, ^ref, :process, ^pid, reason} -> raise "measured process died: #{inspect(reason)}"
    end

    # The worker sends :result_size before it exits, so once the DOWN message
    # has been seen it is guaranteed to be in the mailbox.
    result_bytes =
      receive do
        {:result_size, bytes} -> bytes
      after
        0 -> raise "missing result size message"
      end

    _ = sampler
    %{peak: peak, result_bytes: result_bytes}
  end

  defp sample_loop(pid, max) do
    case :erlang.process_info(pid, :memory) do
      {:memory, bytes} -> sample_loop(pid, max(bytes, max))
      :undefined -> max
    end
  end

  def run_scenario(name, fun, rounds) do
    results = for _ <- 1..rounds, do: measure(fun)
    peaks = Enum.map(results, & &1.peak)
    # The result is deterministic, so its size is the same in every round.
    payload = hd(results).result_bytes
    peak = median(peaks)
    ratio = if payload > 0, do: peak / payload, else: 0.0

    :io.format(
      "~-28s peak: ~7.2f MB   payload: ~5.2f MB   ratio: ~5.1fx   (min ~.2f, max ~.2f over ~b rounds)~n",
      [
        name,
        peak / 1_048_576,
        payload / 1_048_576,
        ratio,
        Enum.min(peaks) / 1_048_576,
        Enum.max(peaks) / 1_048_576,
        rounds
      ]
    )
  end

  defp median(list) do
    sorted = Enum.sort(list)
    Enum.at(sorted, div(length(sorted), 2))
  end
end

MemBench.seed_data()

tail = MemBench.resolution_tail()
bp_things = MemBench.prepare("{ things { a b } }")
bp_strings = MemBench.prepare("{ strings }")
bp_strings_nn = MemBench.prepare("{ stringsNonNull }")

MemBench.sanity_check!(bp_things, bp_strings, bp_strings_nn, tail)

rounds = 7

MemBench.Peak.run_scenario(
  "20k objects / 40k leaves",
  fn -> MemBench.resolve(bp_things, tail) end,
  rounds
)

MemBench.Peak.run_scenario(
  "100k strings [String]",
  fn -> MemBench.resolve(bp_strings, tail) end,
  rounds
)

MemBench.Peak.run_scenario(
  "100k strings [String!]",
  fn -> MemBench.resolve(bp_strings_nn, tail) end,
  rounds
)
