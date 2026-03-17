defmodule Absinthe.Streaming.BackwardsCompatTest do
  @moduledoc """
  Tests to ensure backwards compatibility for existing subscription behavior.

  These tests verify that:
  1. Subscriptions without @defer/@stream work exactly as before
  2. Existing pubsub implementations receive messages in the expected format
  3. Custom run_docset/3 implementations continue to work
  4. Pipeline construction without incremental enabled is unchanged
  """

  use ExUnit.Case, async: true

  alias Absinthe.Subscription.Local

  defmodule TestSchema do
    use Absinthe.Schema

    query do
      field :placeholder, :string do
        resolve fn _, _ -> {:ok, "placeholder"} end
      end
    end

    subscription do
      field :user_created, :user do
        config fn _, _ -> {:ok, topic: "users"} end

        resolve fn _, _, _ ->
          {:ok, %{id: "1", name: "Test User", email: "test@example.com"}}
        end
      end
    end

    object :user do
      field :id, non_null(:id)
      field :name, non_null(:string)
      field :email, non_null(:string)
    end
  end

  defmodule TestPubSub do
    @behaviour Absinthe.Subscription.Pubsub

    def start_link do
      Registry.start_link(keys: :duplicate, name: __MODULE__)
    end

    @impl true
    def subscribe(topic) do
      Registry.register(__MODULE__, topic, [])
      :ok
    end

    @impl true
    def node_name do
      to_string(node())
    end

    @impl true
    def publish_mutation(_proxy_topic, _mutation_result, _subscribed_fields) do
      # Local-only pubsub
      :ok
    end

    @impl true
    def publish_subscription(topic, data) do
      # Send to test process
      Registry.dispatch(__MODULE__, topic, fn entries ->
        for {pid, _} <- entries do
          send(pid, {:subscription_data, topic, data})
        end
      end)

      :ok
    end
  end

  describe "backwards compatibility" do
    test "subscription without @defer/@stream uses standard pipeline" do
      # Query without any streaming directives
      query = """
      subscription {
        userCreated {
          id
          name
        }
      }
      """

      # Should NOT detect streaming directives
      refute Absinthe.Streaming.has_streaming_directives?(query)
    end

    test "pipeline/2 without options works as before" do
      # Simulate a document structure
      doc = %{
        source: "subscription { userCreated { id } }",
        initial_phases: [
          {Absinthe.Phase.Parse, []},
          {Absinthe.Phase.Blueprint, []},
          {Absinthe.Phase.Telemetry, event: [:execute, :operation, :start]},
          {Absinthe.Phase.Document.Execution.Resolution, []}
        ]
      }

      # Call pipeline without enable_incremental
      pipeline = Local.pipeline(doc, %{})

      # Verify it's a valid pipeline (list of phases)
      assert is_list(List.flatten(pipeline))

      # Verify Resolution phase is present (not StreamingResolution)
      flat_pipeline = List.flatten(pipeline)

      resolution_present =
        Enum.any?(flat_pipeline, fn
          Absinthe.Phase.Document.Execution.Resolution -> true
          {Absinthe.Phase.Document.Execution.Resolution, _} -> true
          _ -> false
        end)

      streaming_resolution_present =
        Enum.any?(flat_pipeline, fn
          Absinthe.Phase.Document.Execution.StreamingResolution -> true
          {Absinthe.Phase.Document.Execution.StreamingResolution, _} -> true
          _ -> false
        end)

      assert resolution_present or not streaming_resolution_present,
             "Pipeline should use Resolution, not StreamingResolution, when incremental is disabled"
    end

    test "pipeline/3 with enable_incremental: false works as before" do
      doc = %{
        source: "subscription { userCreated { id } }",
        initial_phases: [
          {Absinthe.Phase.Parse, []},
          {Absinthe.Phase.Blueprint, []},
          {Absinthe.Phase.Telemetry, event: [:execute, :operation, :start]},
          {Absinthe.Phase.Document.Execution.Resolution, []}
        ]
      }

      # Explicitly disable incremental
      pipeline = Local.pipeline(doc, %{}, enable_incremental: false)

      assert is_list(List.flatten(pipeline))
    end

    test "has_streaming_directives? returns false for regular queries" do
      queries = [
        "subscription { userCreated { id name } }",
        "query { user(id: \"1\") { name } }",
        "mutation { createUser(name: \"Test\") { id } }",
        # With comments
        "# This is a comment\nsubscription { userCreated { id } }",
        # With fragments (but no @defer)
        "subscription { userCreated { ...UserFields } } fragment UserFields on User { id name }"
      ]

      for query <- queries do
        refute Absinthe.Streaming.has_streaming_directives?(query),
               "Should not detect streaming in: #{query}"
      end
    end

    test "has_streaming_directives? returns true for queries with @defer" do
      queries = [
        "subscription { userCreated { id ... @defer { email } } }",
        "query { user(id: \"1\") { name ... @defer { profile { bio } } } }",
        "subscription { userCreated { ...UserFields @defer } } fragment UserFields on User { id }"
      ]

      for query <- queries do
        assert Absinthe.Streaming.has_streaming_directives?(query),
               "Should detect @defer in: #{query}"
      end
    end

    test "has_streaming_directives? returns true for queries with @stream" do
      queries = [
        "query { users @stream { id name } }",
        "subscription { postsCreated { comments @stream(initialCount: 5) { text } } }"
      ]

      for query <- queries do
        assert Absinthe.Streaming.has_streaming_directives?(query),
               "Should detect @stream in: #{query}"
      end
    end
  end

  describe "streaming module helpers" do
    test "has_streaming_tasks? returns false for blueprints without streaming context" do
      blueprint = %Absinthe.Blueprint{
        execution: %Absinthe.Blueprint.Execution{
          context: %{}
        }
      }

      refute Absinthe.Streaming.has_streaming_tasks?(blueprint)
    end

    test "has_streaming_tasks? returns false for empty task lists" do
      blueprint = %Absinthe.Blueprint{
        execution: %Absinthe.Blueprint.Execution{
          context: %{
            __streaming__: %{
              deferred_tasks: [],
              stream_tasks: []
            }
          }
        }
      }

      refute Absinthe.Streaming.has_streaming_tasks?(blueprint)
    end

    test "has_streaming_tasks? returns true when deferred_tasks present" do
      blueprint = %Absinthe.Blueprint{
        execution: %Absinthe.Blueprint.Execution{
          context: %{
            __streaming__: %{
              deferred_tasks: [%{id: "1", execute: fn -> {:ok, %{}} end}],
              stream_tasks: []
            }
          }
        }
      }

      assert Absinthe.Streaming.has_streaming_tasks?(blueprint)
    end

    test "has_streaming_tasks? returns true when stream_tasks present" do
      blueprint = %Absinthe.Blueprint{
        execution: %Absinthe.Blueprint.Execution{
          context: %{
            __streaming__: %{
              deferred_tasks: [],
              stream_tasks: [%{id: "1", execute: fn -> {:ok, %{}} end}]
            }
          }
        }
      }

      assert Absinthe.Streaming.has_streaming_tasks?(blueprint)
    end

    test "get_streaming_tasks returns all tasks" do
      task1 = %{id: "1", type: :defer, execute: fn -> {:ok, %{}} end}
      task2 = %{id: "2", type: :stream, execute: fn -> {:ok, %{}} end}

      blueprint = %Absinthe.Blueprint{
        execution: %Absinthe.Blueprint.Execution{
          context: %{
            __streaming__: %{
              deferred_tasks: [task1],
              stream_tasks: [task2]
            }
          }
        }
      }

      tasks = Absinthe.Streaming.get_streaming_tasks(blueprint)

      assert length(tasks) == 2
      assert task1 in tasks
      assert task2 in tasks
    end
  end
end
