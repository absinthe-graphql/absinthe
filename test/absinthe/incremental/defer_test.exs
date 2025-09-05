defmodule Absinthe.Incremental.DeferTest do
  @moduledoc """
  Integration tests for @defer directive functionality.
  """
  
  use ExUnit.Case, async: true
  
  alias Absinthe.{Pipeline, Phase}
  alias Absinthe.Incremental.{Response, Config}
  
  defmodule TestSchema do
    use Absinthe.Schema
    
    query do
      field :user, :user do
        arg :id, non_null(:id)
        
        resolve fn %{id: id}, _ ->
          {:ok, %{
            id: id,
            name: "User #{id}",
            email: "user#{id}@example.com"
          }}
        end
      end
      
      field :expensive_data, :expensive_data do
        resolve fn _, _ ->
          # Simulate immediate data
          {:ok, %{
            quick_field: "immediate",
            nested: %{value: "nested immediate"}
          }}
        end
      end
    end
    
    object :user do
      field :id, non_null(:id)
      field :name, non_null(:string)
      field :email, non_null(:string)
      
      field :profile, :profile do
        resolve fn user, _ ->
          # Simulate expensive operation
          Process.sleep(10)
          {:ok, %{
            bio: "Bio for #{user.name}",
            avatar: "avatar_#{user.id}.jpg",
            followers: 100
          }}
        end
      end
      
      field :posts, list_of(:post) do
        resolve fn user, _ ->
          # Simulate expensive operation
          Process.sleep(20)
          {:ok, [
            %{id: "1", title: "Post 1 by #{user.name}"},
            %{id: "2", title: "Post 2 by #{user.name}"}
          ]}
        end
      end
    end
    
    object :profile do
      field :bio, :string
      field :avatar, :string
      field :followers, :integer
    end
    
    object :post do
      field :id, non_null(:id)
      field :title, non_null(:string)
    end
    
    object :expensive_data do
      field :quick_field, :string
      
      field :slow_field, :string do
        resolve fn _, _ ->
          Process.sleep(30)
          {:ok, "slow data"}
        end
      end
      
      field :nested, :nested_data
    end
    
    object :nested_data do
      field :value, :string
      
      field :expensive_value, :string do
        resolve fn _, _ ->
          Process.sleep(25)
          {:ok, "expensive nested"}
        end
      end
    end
  end
  
  setup do
    # Start the incremental delivery supervisor if not already started
    case Absinthe.Incremental.Supervisor.start_link(
      enabled: true,
      enable_defer: true,
      enable_stream: true
    ) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end
    
    :ok
  end
  
  describe "@defer directive" do
    test "defers a fragment spread" do
      query = """
      query GetUser($userId: ID!) {
        user(id: $userId) {
          id
          name
          ...UserProfile @defer(label: "profile")
        }
      }
      
      fragment UserProfile on User {
        email
        profile {
          bio
          avatar
        }
      }
      """
      
      result = run_streaming_query(query, %{"userId" => "123"})
      
      # Check initial response
      assert result.initial.data == %{
        "user" => %{
          "id" => "123",
          "name" => "User 123"
        }
      }
      
      assert length(result.initial.pending) == 1
      assert hd(result.initial.pending).label == "profile"
      
      # Check deferred response
      assert length(result.incremental) == 1
      deferred = hd(result.incremental)
      
      assert deferred.data == %{
        "email" => "user123@example.com",
        "profile" => %{
          "bio" => "Bio for User 123",
          "avatar" => "avatar_123.jpg"
        }
      }
    end
    
    test "defers an inline fragment" do
      query = """
      query GetUser($userId: ID!) {
        user(id: $userId) {
          id
          name
          ... @defer(label: "details") {
            email
            posts {
              id
              title
            }
          }
        }
      }
      """
      
      result = run_streaming_query(query, %{"userId" => "456"})
      
      # Initial response should only have id and name
      assert result.initial.data == %{
        "user" => %{
          "id" => "456",
          "name" => "User 456"
        }
      }
      
      # Deferred response should have email and posts
      deferred = hd(result.incremental)
      assert deferred.data["email"] == "user456@example.com"
      assert length(deferred.data["posts"]) == 2
    end
    
    test "handles conditional defer with if: false" do
      query = """
      query GetUser($userId: ID!, $shouldDefer: Boolean!) {
        user(id: $userId) {
          id
          name
          ... @defer(if: $shouldDefer, label: "conditional") {
            email
            profile {
              bio
            }
          }
        }
      }
      """
      
      # With defer disabled
      result = run_query(query, %{"userId" => "789", "shouldDefer" => false})
      
      # Everything should be in initial response
      assert result.data == %{
        "user" => %{
          "id" => "789",
          "name" => "User 789",
          "email" => "user789@example.com",
          "profile" => %{
            "bio" => "Bio for User 789"
          }
        }
      }
      
      # No pending operations
      assert Map.get(result, :pending) == nil
    end
    
    test "handles nested defer directives" do
      query = """
      query GetExpensiveData {
        expensiveData {
          quickField
          ... @defer(label: "level1") {
            slowField
            nested {
              value
              ... @defer(label: "level2") {
                expensiveValue
              }
            }
          }
        }
      }
      """
      
      result = run_streaming_query(query, %{})
      
      # Initial response has only quick field
      assert result.initial.data == %{
        "expensiveData" => %{
          "quickField" => "immediate"
        }
      }
      
      # Should have 2 pending operations
      assert length(result.initial.pending) == 2
      
      # First deferred response
      level1 = Enum.find(result.incremental, & &1.label == "level1")
      assert level1.data["slowField"] == "slow data"
      assert level1.data["nested"]["value"] == "nested immediate"
      
      # Second deferred response
      level2 = Enum.find(result.incremental, & &1.label == "level2")
      assert level2.data["expensiveValue"] == "expensive nested"
    end
    
    test "handles defer with errors in deferred fragment" do
      query = """
      query GetUser($userId: ID!) {
        user(id: $userId) {
          id
          name
          ... @defer(label: "errorFragment") {
            nonExistentField
          }
        }
      }
      """
      
      result = run_streaming_query(query, %{"userId" => "999"})
      
      # Initial response should succeed
      assert result.initial.data["user"]["id"] == "999"
      
      # Deferred response should contain error
      deferred = hd(result.incremental)
      assert deferred.errors != nil
    end
  end
  
  describe "defer with multiple fragments" do
    test "defers multiple fragments independently" do
      query = """
      query GetUser($userId: ID!) {
        user(id: $userId) {
          id
          ... @defer(label: "names") {
            name
          }
          ... @defer(label: "contact") {
            email
          }
          ... @defer(label: "content") {
            posts {
              title
            }
          }
        }
      }
      """
      
      result = run_streaming_query(query, %{"userId" => "multi"})
      
      # Initial response has only id
      assert result.initial.data == %{"user" => %{"id" => "multi"}}
      
      # Should have 3 pending operations
      assert length(result.initial.pending) == 3
      
      # All three fragments should be delivered
      assert length(result.incremental) == 3
      
      labels = Enum.map(result.incremental, & &1.label)
      assert "names" in labels
      assert "contact" in labels
      assert "content" in labels
    end
  end
  
  # Helper functions
  
  defp run_query(query, variables \\ %{}) do
    {:ok, result} = Absinthe.run(query, TestSchema, 
      variables: variables,
      context: %{}
    )
    result
  end
  
  defp run_streaming_query(query, variables \\ %{}) do
    # For now, just run a standard query to test basic functionality
    case Absinthe.run(query, TestSchema, variables: variables) do
      {:ok, result} -> 
        # Simulate streaming response structure for testing
        %{
          initial: result,
          incremental: []
        }
      error -> 
        error
    end
  end
  
  defp streaming_pipeline(schema, config) do
    schema
    |> Absinthe.Pipeline.for_document(context: %{incremental_config: config})
    |> replace_resolution_phase()
  end
  
  defp replace_resolution_phase(pipeline) do
    Enum.map(pipeline, fn
      {Phase.Document.Execution.Resolution, opts} ->
        {Absinthe.Phase.Document.Execution.StreamingResolution, opts}
      
      phase ->
        phase
    end)
  end
  
  defp collect_streaming_responses(blueprint) do
    initial = Response.build_initial(blueprint)
    
    # Simulate async execution of deferred tasks
    streaming_context = get_in(blueprint, [:execution, :context, :__streaming__])
    
    incremental = 
      if streaming_context do
        collect_deferred_responses(streaming_context)
      else
        []
      end
    
    %{
      initial: initial,
      incremental: incremental
    }
  end
  
  defp collect_deferred_responses(streaming_context) do
    tasks = Map.get(streaming_context, :deferred_tasks, [])
    
    Enum.map(tasks, fn task ->
      # Execute the deferred task
      result = task.execute.()
      
      %{
        data: result[:data],
        label: task.label,
        path: task.path
      }
    end)
  end
end