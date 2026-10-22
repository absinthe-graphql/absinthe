defmodule Absinthe.Phase.TelemetryTest do
  use Absinthe.Case, async: false

  @operation_start [:absinthe, :execute, :operation, :start]
  @operation_stop [:absinthe, :execute, :operation, :stop]
  @operation_exception [:absinthe, :execute, :operation, :exception]

  defmodule Schema do
    use Absinthe.Schema

    query do
      field :ok_thing, :string do
        resolve fn _, _, _ -> {:ok, "fine"} end
      end

      field :raising_thing, :string do
        resolve fn _, _, _ -> raise "kaboom" end
      end
    end
  end

  test "emits :start and :stop on success without emitting :exception" do
    ref =
      :telemetry_test.attach_event_handlers(self(), [
        @operation_start,
        @operation_stop,
        @operation_exception
      ])

    assert {:ok, %{data: %{"okThing" => "fine"}}} = Absinthe.run("{ okThing }", Schema)

    assert_receive {@operation_start, ^ref, %{system_time: _}, %{id: id}}
    assert_receive {@operation_stop, ^ref, %{duration: _}, %{id: ^id}}
    refute_received {@operation_exception, ^ref, _, _}
  end

  test "emits :exception when a resolver raises anywhere in the pipeline and re-raises" do
    ref =
      :telemetry_test.attach_event_handlers(self(), [
        @operation_start,
        @operation_stop,
        @operation_exception
      ])

    assert_raise RuntimeError, "kaboom", fn ->
      Absinthe.run("{ raisingThing }", Schema)
    end

    assert_receive {@operation_start, ^ref, %{system_time: _}, %{id: id}}

    assert_receive {@operation_exception, ^ref, %{},
                    %{
                      id: ^id,
                      telemetry_span_context: ^id,
                      kind: :error,
                      reason: %RuntimeError{message: "kaboom"},
                      stacktrace: _
                    }}

    refute_received {@operation_stop, ^ref, _, _}
  end
end
