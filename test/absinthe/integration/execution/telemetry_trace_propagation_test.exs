defmodule Elixir.Absinthe.Integration.Execution.TelemetryTracePropagationTest do
  use Absinthe.Case, async: true
  import ExUnit.Assertions

  setup context do
    :telemetry.attach_many(
      context.test,
      [
        [:absinthe, :resolve, :field, :start],
        [:absinthe, :resolve, :field],
        [:absinthe, :execute, :operation, :start],
        [:absinthe, :execute, :operation]
      ],
      &__MODULE__.handle_event/4,
      %{}
    )

    on_exit(fn ->
      :telemetry.detach(context.test)
    end)

    :ok
  end

  def handle_event(event, measurements, metadata, config) do
    send(self(), {event, measurements, metadata, config})
  end

  defmodule TestSchema do
    use Absinthe.Schema

    object :field_resolution_timing do
      field :begin_ms, :integer
      field :delay_ms, :integer
      field :end_ms, :integer
      field :label, :integer
    end

    query do
      field :delay_sync, :field_resolution_timing do
        arg :delay_ms, :integer

        resolve fn _, %{delay_ms: delay_ms}, _ ->
          {:ok, delay_and_report(:delay_sync, delay_ms)}
        end
      end

      field :delay_async, :field_resolution_timing do
        arg :delay_ms, :integer

        resolve fn _, %{delay_ms: delay_ms}, _ ->
          async(fn ->
            {:ok, delay_and_report(:delay_async, delay_ms)}
          end)
        end
      end
    end

    def delay_and_report(field_name, delay_ms)
        when is_atom(field_name) and is_integer(delay_ms) do
      begin_ms = :os.system_time(:milli_seconds)
      :timer.sleep(delay_ms)
      end_ms = :os.system_time(:milli_seconds)

      %{
        begin_ms: begin_ms,
        delay_ms: delay_ms,
        end_ms: end_ms,
        label: label()
      }
    end

    defp label do
      case :seq_trace.get_token(:label) do
        [] -> 0
        {:label, n} -> n
      end
    end
  end

  test "Execute expected telemetry events" do
    query = """
    query AskForAsyncThenSync ($delay_ms_async: Int!, $delay_ms_sync: Int!) {
      delayAsync(delay_ms: $delay_ms_async) {
        begin_ms
        delay_ms
        end_ms
        label
      }
      delaySync(delay_ms: $delay_ms_sync) {
        begin_ms
        delay_ms
        end_ms
        label
      }
    }
    """

    :seq_trace.set_token(:label, 23)

    delay_ms_async = 10
    delay_ms_sync = 100

    {:ok, %{data: data}} =
      Absinthe.run(query, TestSchema,
        variables: %{"delay_ms_async" => delay_ms_async, "delay_ms_sync" => delay_ms_sync}
      )

    :seq_trace.set_token([])

    assert %{"delayAsync" => result_async, "delaySync" => result_sync} = data
    assert_in_delta(duration_ms(result_async), delay_ms_async, delay_ms_async / 10)
    assert_in_delta(duration_ms(result_sync), delay_ms_sync, delay_ms_sync / 10)

    IO.inspect({result_async, result_sync}, label: "results")
    IO.inspect(duration_ms(result_async), label: "result_async duration_ms")
    IO.inspect(duration_ms(result_sync), label: "result_sync duration_ms")
    IO.inspect(overlap?(result_async, result_sync), label: "overlap")

    assert_receive {[:absinthe, :resolve, :field], measurements1, _, _}
    assert_receive {[:absinthe, :resolve, :field], measurements2, _, _}
    assert is_number(measurements1[:duration])
    assert is_number(measurements2[:duration])

    [slower, faster] =
      [measurements1, measurements2] |> Enum.map(& &1.duration) |> Enum.map(&(&1 / 1_000_000))

    IO.inspect([slower, faster], label: ":telemetry reported durations (ms)")
    assert_in_delta(faster, delay_ms_async, delay_ms_async / 10)
    assert_in_delta(slower, delay_ms_sync, delay_ms_sync / 10)
  end

  defp duration_ms(%{"begin_ms" => begin_ms, "end_ms" => end_ms}), do: end_ms - begin_ms

  defp overlap?(%{"begin_ms" => begin_ms_a, "end_ms" => end_ms_a}, %{
         "begin_ms" => begin_ms_b,
         "end_ms" => end_ms_b
       }),
       do: not (end_ms_a <= begin_ms_b or begin_ms_a >= end_ms_b)
end
