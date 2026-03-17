defmodule Absinthe.Streaming.TaskExecutorTest do
  @moduledoc """
  Tests for the TaskExecutor module.
  """

  use ExUnit.Case, async: true

  alias Absinthe.Streaming.TaskExecutor

  describe "execute_stream/2" do
    test "executes tasks and returns results as stream" do
      tasks = [
        %{
          id: "1",
          type: :defer,
          label: "first",
          path: ["user", "profile"],
          execute: fn -> {:ok, %{data: %{bio: "Test bio"}}} end
        },
        %{
          id: "2",
          type: :defer,
          label: "second",
          path: ["user", "posts"],
          execute: fn -> {:ok, %{data: %{title: "Test post"}}} end
        }
      ]

      results = tasks |> TaskExecutor.execute_stream() |> Enum.to_list()

      assert length(results) == 2

      [first, second] = results

      assert first.success == true
      assert first.has_next == true
      assert first.result == {:ok, %{data: %{bio: "Test bio"}}}

      assert second.success == true
      assert second.has_next == false
      assert second.result == {:ok, %{data: %{title: "Test post"}}}
    end

    test "handles task errors gracefully" do
      tasks = [
        %{
          id: "1",
          type: :defer,
          label: nil,
          path: ["error"],
          execute: fn -> {:error, "Something went wrong"} end
        }
      ]

      results = tasks |> TaskExecutor.execute_stream() |> Enum.to_list()

      assert length(results) == 1
      [result] = results

      assert result.success == false
      assert result.has_next == false
      assert {:error, "Something went wrong"} = result.result
    end

    test "handles task exceptions" do
      tasks = [
        %{
          id: "1",
          type: :defer,
          label: nil,
          path: ["exception"],
          execute: fn -> raise "Boom!" end
        }
      ]

      results = tasks |> TaskExecutor.execute_stream() |> Enum.to_list()

      assert length(results) == 1
      [result] = results

      assert result.success == false
      assert {:error, _} = result.result
    end

    test "respects timeout option" do
      tasks = [
        %{
          id: "1",
          type: :defer,
          label: nil,
          path: ["slow"],
          execute: fn ->
            Process.sleep(5000)
            {:ok, %{data: %{}}}
          end
        }
      ]

      results = tasks |> TaskExecutor.execute_stream(timeout: 100) |> Enum.to_list()

      assert length(results) == 1
      [result] = results

      assert result.success == false
      assert result.result == {:error, :timeout}
    end

    test "tracks duration" do
      tasks = [
        %{
          id: "1",
          type: :defer,
          label: nil,
          path: ["timed"],
          execute: fn ->
            Process.sleep(50)
            {:ok, %{data: %{}}}
          end
        }
      ]

      results = tasks |> TaskExecutor.execute_stream() |> Enum.to_list()

      [result] = results
      assert result.duration_ms >= 50
    end

    test "handles empty task list" do
      results = [] |> TaskExecutor.execute_stream() |> Enum.to_list()
      assert results == []
    end
  end

  describe "execute_all/2" do
    test "collects all results into a list" do
      tasks = [
        %{
          id: "1",
          type: :defer,
          label: "a",
          path: ["a"],
          execute: fn -> {:ok, %{data: %{a: 1}}} end
        },
        %{
          id: "2",
          type: :defer,
          label: "b",
          path: ["b"],
          execute: fn -> {:ok, %{data: %{b: 2}}} end
        }
      ]

      results = TaskExecutor.execute_all(tasks)

      assert length(results) == 2
      assert Enum.all?(results, & &1.success)
    end
  end

  describe "execute_one/2" do
    test "executes a single task" do
      task = %{
        id: "1",
        type: :defer,
        label: "single",
        path: ["single"],
        execute: fn -> {:ok, %{data: %{value: 42}}} end
      }

      result = TaskExecutor.execute_one(task)

      assert result.success == true
      assert result.has_next == false
      assert result.result == {:ok, %{data: %{value: 42}}}
    end

    test "handles timeout for single task" do
      task = %{
        id: "1",
        type: :defer,
        label: nil,
        path: ["slow"],
        execute: fn ->
          Process.sleep(5000)
          {:ok, %{}}
        end
      }

      result = TaskExecutor.execute_one(task, timeout: 100)

      assert result.success == false
      assert result.result == {:error, :timeout}
    end
  end
end
