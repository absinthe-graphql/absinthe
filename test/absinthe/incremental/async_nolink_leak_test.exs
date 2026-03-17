defmodule Absinthe.Incremental.TaskMailboxLeakTest do
  use ExUnit.Case

  alias Absinthe.Incremental.Supervisor, as: IncrSupervisor

  setup do
    start_supervised!({IncrSupervisor, [enabled: true]})
    :ok
  end

  test "start_deferred_task/1 does not leak messages into the caller mailbox" do
    {:ok, _pid} = IncrSupervisor.start_deferred_task(fn -> :done end)
    Process.sleep(50)

    assert {:messages, []} = Process.info(self(), :messages)
  end

  test "start_stream_task/1 does not leak messages into the caller mailbox" do
    {:ok, _pid} = IncrSupervisor.start_stream_task(fn -> :done end)
    Process.sleep(50)

    assert {:messages, []} = Process.info(self(), :messages)
  end
end
