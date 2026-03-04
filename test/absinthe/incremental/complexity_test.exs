defmodule Absinthe.Incremental.ComplexityTest do
  @moduledoc """
  Tests for complexity analysis with incremental delivery.

  Verifies that:
  - Total query complexity is calculated correctly with @defer/@stream
  - Per-chunk complexity limits are enforced
  - Multipliers are applied correctly for deferred/streamed operations
  """

  use ExUnit.Case, async: true

  alias Absinthe.{Pipeline, Blueprint}
  alias Absinthe.Incremental.Complexity

  defmodule TestSchema do
    use Absinthe.Schema

    import_directives Absinthe.Type.BuiltIns.IncrementalDirectives

    query do
      field :user, :user do
        resolve fn _, _ -> {:ok, %{id: "1", name: "Test User"}} end
      end

      field :users, list_of(:user) do
        resolve fn _, _ ->
          {:ok, Enum.map(1..10, fn i -> %{id: "#{i}", name: "User #{i}"} end)}
        end
      end

      field :posts, list_of(:post) do
        resolve fn _, _ ->
          {:ok, Enum.map(1..20, fn i -> %{id: "#{i}", title: "Post #{i}"} end)}
        end
      end
    end

    object :user do
      field :id, non_null(:id)
      field :name, non_null(:string)

      field :profile, :profile do
        resolve fn _, _, _ -> {:ok, %{bio: "Bio", avatar: "avatar.jpg"}} end
      end

      field :posts, list_of(:post) do
        resolve fn _, _, _ ->
          {:ok, Enum.map(1..5, fn i -> %{id: "#{i}", title: "Post #{i}"} end)}
        end
      end
    end

    object :profile do
      field :bio, :string
      field :avatar, :string

      field :settings, :settings do
        resolve fn _, _, _ -> {:ok, %{theme: "dark"}} end
      end
    end

    object :settings do
      field :theme, :string
    end

    object :post do
      field :id, non_null(:id)
      field :title, non_null(:string)

      field :comments, list_of(:comment) do
        resolve fn _, _, _ ->
          {:ok, Enum.map(1..5, fn i -> %{id: "#{i}", text: "Comment #{i}"} end)}
        end
      end
    end

    object :comment do
      field :id, non_null(:id)
      field :text, non_null(:string)
    end
  end

  describe "analyze/2" do
    test "calculates complexity for simple query" do
      query = """
      query {
        user {
          id
          name
        }
      }
      """

      {:ok, blueprint} = run_phases(query)
      {:ok, info} = Complexity.analyze(blueprint)

      assert info.total_complexity > 0
      assert info.defer_count == 0
      assert info.stream_count == 0
    end

    test "calculates complexity with @defer" do
      query = """
      query {
        user {
          id
          ... @defer(label: "profile") {
            name
            profile {
              bio
            }
          }
        }
      }
      """

      {:ok, blueprint} = run_phases(query)
      {:ok, info} = Complexity.analyze(blueprint)

      assert info.defer_count == 1
      assert info.max_defer_depth >= 1
      # Initial + deferred
      assert info.estimated_payloads >= 2
    end

    test "calculates complexity with @stream" do
      query = """
      query {
        users @stream(initialCount: 3) {
          id
          name
        }
      }
      """

      {:ok, blueprint} = run_phases(query)
      {:ok, info} = Complexity.analyze(blueprint)

      assert info.stream_count == 1
      # Initial + streamed batches
      assert info.estimated_payloads >= 2
    end

    test "tracks nested @defer depth" do
      query = """
      query {
        user {
          id
          ... @defer(label: "level1") {
            name
            profile {
              bio
              ... @defer(label: "level2") {
                settings {
                  theme
                }
              }
            }
          }
        }
      }
      """

      {:ok, blueprint} = run_phases(query)
      {:ok, info} = Complexity.analyze(blueprint)

      assert info.defer_count == 2
      assert info.max_defer_depth >= 2
    end

    test "tracks multiple @defer operations" do
      query = """
      query {
        user {
          id
          ... @defer(label: "name") { name }
          ... @defer(label: "profile") { profile { bio } }
          ... @defer(label: "posts") { posts { title } }
        }
      }
      """

      {:ok, blueprint} = run_phases(query)
      {:ok, info} = Complexity.analyze(blueprint)

      assert info.defer_count == 3
      # Initial + 3 deferred
      assert info.estimated_payloads >= 4
    end

    test "provides breakdown by type" do
      query = """
      query {
        user {
          id
          name
          ... @defer(label: "extra") {
            profile { bio }
          }
        }
        posts @stream(initialCount: 5) {
          title
        }
      }
      """

      {:ok, blueprint} = run_phases(query)
      {:ok, info} = Complexity.analyze(blueprint)

      assert Map.has_key?(info.breakdown, :immediate)
      assert Map.has_key?(info.breakdown, :deferred)
      assert Map.has_key?(info.breakdown, :streamed)
    end
  end

  describe "per-chunk complexity" do
    test "tracks complexity per chunk" do
      query = """
      query {
        user {
          id
          ... @defer(label: "heavy") {
            posts {
              title
              comments { text }
            }
          }
        }
      }
      """

      {:ok, blueprint} = run_phases(query)
      {:ok, info} = Complexity.analyze(blueprint)

      # Should have chunk complexities
      assert length(info.chunk_complexities) >= 1
    end
  end

  describe "check_limits/2" do
    test "passes when under all limits" do
      query = """
      query {
        user {
          id
          name
        }
      }
      """

      {:ok, blueprint} = run_phases(query)
      assert :ok == Complexity.check_limits(blueprint)
    end

    test "fails when total complexity exceeded" do
      query = """
      query {
        users @stream(initialCount: 0) {
          posts {
            comments { text }
          }
        }
      }
      """

      {:ok, blueprint} = run_phases(query)

      # Set a very low limit
      result = Complexity.check_limits(blueprint, %{max_complexity: 1})

      assert {:error, {:complexity_exceeded, _, 1}} = result
    end

    test "fails when too many @defer operations" do
      query = """
      query {
        user {
          ... @defer { name }
          ... @defer { profile { bio } }
          ... @defer { posts { title } }
        }
      }
      """

      {:ok, blueprint} = run_phases(query)

      result = Complexity.check_limits(blueprint, %{max_defer_operations: 2})

      assert {:error, {:too_many_defers, 3}} = result
    end

    test "fails when @defer nesting too deep" do
      query = """
      query {
        user {
          ... @defer(label: "l1") {
            profile {
              ... @defer(label: "l2") {
                settings {
                  theme
                }
              }
            }
          }
        }
      }
      """

      {:ok, blueprint} = run_phases(query)

      result = Complexity.check_limits(blueprint, %{max_defer_depth: 1})

      assert {:error, {:defer_too_deep, _}} = result
    end

    test "fails when too many @stream operations" do
      query = """
      query {
        users @stream(initialCount: 1) { id }
        posts @stream(initialCount: 1) { id }
      }
      """

      {:ok, blueprint} = run_phases(query)

      result = Complexity.check_limits(blueprint, %{max_stream_operations: 1})

      assert {:error, {:too_many_streams, 2}} = result
    end
  end

  describe "field_cost/3" do
    test "calculates base field cost" do
      cost = Complexity.field_cost(%{type: :string}, %{})
      assert cost > 0
    end

    test "applies defer multiplier" do
      base_cost = Complexity.field_cost(%{type: :string}, %{})
      defer_cost = Complexity.field_cost(%{type: :string}, %{defer: true})

      assert defer_cost > base_cost
    end

    test "applies stream multiplier" do
      base_cost = Complexity.field_cost(%{type: :string}, %{})
      stream_cost = Complexity.field_cost(%{type: :string}, %{stream: true})

      assert stream_cost > base_cost
    end

    test "stream has higher multiplier than defer" do
      defer_cost = Complexity.field_cost(%{type: :string}, %{defer: true})
      stream_cost = Complexity.field_cost(%{type: :string}, %{stream: true})

      # Stream typically costs more due to multiple payloads
      assert stream_cost > defer_cost
    end
  end

  describe "summary/2" do
    test "returns summary for telemetry" do
      query = """
      query {
        user {
          id
          ... @defer { name }
        }
        posts @stream(initialCount: 5) { title }
      }
      """

      {:ok, blueprint} = run_phases(query)
      summary = Complexity.summary(blueprint)

      assert Map.has_key?(summary, :total)
      assert Map.has_key?(summary, :defers)
      assert Map.has_key?(summary, :streams)
      assert Map.has_key?(summary, :payloads)
      assert Map.has_key?(summary, :chunks)
    end
  end

  # Helper functions

  defp run_phases(query, variables \\ %{}) do
    pipeline =
      TestSchema
      |> Pipeline.for_document(variables: variables)
      |> Pipeline.without(Absinthe.Phase.Document.Execution.Resolution)
      |> Pipeline.without(Absinthe.Phase.Document.Result)

    case Absinthe.Pipeline.run(query, pipeline) do
      {:ok, blueprint, _phases} -> {:ok, blueprint}
      error -> error
    end
  end
end
