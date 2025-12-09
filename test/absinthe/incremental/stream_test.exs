defmodule Absinthe.Incremental.StreamTest do
  @moduledoc """
  Integration tests for @stream directive functionality.
  """
  
  use ExUnit.Case, async: true
  
  alias Absinthe.Incremental.{Response, Config}
  
  defmodule TestSchema do
    use Absinthe.Schema
    
    @users [
      %{id: "1", name: "Alice", age: 30},
      %{id: "2", name: "Bob", age: 25},
      %{id: "3", name: "Charlie", age: 35},
      %{id: "4", name: "Diana", age: 28},
      %{id: "5", name: "Eve", age: 32},
      %{id: "6", name: "Frank", age: 45},
      %{id: "7", name: "Grace", age: 29},
      %{id: "8", name: "Henry", age: 31},
      %{id: "9", name: "Iris", age: 27},
      %{id: "10", name: "Jack", age: 33}
    ]
    
    query do
      field :users, list_of(:user) do
        arg :limit, :integer
        
        resolve fn args, _ ->
          users = 
            case Map.get(args, :limit) do
              nil -> @users
              limit -> Enum.take(@users, limit)
            end
          
          # Simulate some processing time
          Process.sleep(10)
          {:ok, users}
        end
      end
      
      field :search, :search_result do
        arg :query, non_null(:string)
        
        resolve fn %{query: query}, _ ->
          # Simulate search
          users = Enum.filter(@users, fn user ->
            String.contains?(String.downcase(user.name), String.downcase(query))
          end)
          
          {:ok, %{users: users, count: length(users)}}
        end
      end
      
      field :posts, list_of(:post) do
        resolve fn _, _ ->
          posts = Enum.map(1..20, fn i ->
            %{
              id: "post_#{i}",
              title: "Post #{i}",
              content: "Content for post #{i}"
            }
          end)
          
          {:ok, posts}
        end
      end
    end
    
    object :user do
      field :id, non_null(:id)
      field :name, non_null(:string)
      field :age, :integer
      
      field :friends, list_of(:user) do
        resolve fn user, _ ->
          # Return some friends (excluding self)
          friends = Enum.reject(@users, & &1.id == user.id)
          |> Enum.take(3)
          
          {:ok, friends}
        end
      end
    end
    
    object :post do
      field :id, non_null(:id)
      field :title, non_null(:string)
      field :content, :string
      
      field :comments, list_of(:comment) do
        resolve fn post, _ ->
          comments = Enum.map(1..5, fn i ->
            %{
              id: "#{post.id}_comment_#{i}",
              text: "Comment #{i} on #{post.title}"
            }
          end)
          
          {:ok, comments}
        end
      end
    end
    
    object :comment do
      field :id, non_null(:id)
      field :text, non_null(:string)
    end
    
    object :search_result do
      field :users, list_of(:user)
      field :count, :integer
    end
  end
  
  setup do
    # Start the incremental delivery supervisor if not already started
    case Absinthe.Incremental.Supervisor.start_link(
      enabled: true,
      enable_stream: true,
      default_stream_batch_size: 3
    ) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end
    
    :ok
  end
  
  describe "@stream directive" do
    test "streams a list with initial count" do
      query = """
      query GetUsers {
        users @stream(initialCount: 2, label: "moreUsers") {
          id
          name
        }
      }
      """
      
      result = run_streaming_query(query)
      
      # Initial response should have first 2 users
      initial_users = result.initial.data["users"]
      assert length(initial_users) == 2
      assert Enum.at(initial_users, 0)["name"] == "Alice"
      assert Enum.at(initial_users, 1)["name"] == "Bob"
      
      # Should have pending stream operation
      assert length(result.initial.pending) == 1
      assert hd(result.initial.pending).label == "moreUsers"
      
      # Stream responses should have remaining users
      streamed_items = collect_streamed_items(result.incremental)
      assert length(streamed_items) == 8  # 10 total - 2 initial
    end
    
    test "streams with initialCount of 0" do
      query = """
      query GetUsers {
        users(limit: 5) @stream(initialCount: 0, label: "allUsers") {
          id
          name
        }
      }
      """
      
      result = run_streaming_query(query)
      
      # Initial response should have empty list
      assert result.initial.data["users"] == []
      
      # All items should be streamed
      streamed_items = collect_streamed_items(result.incremental)
      assert length(streamed_items) == 5
    end
    
    test "handles conditional stream with if: false" do
      query = """
      query GetUsers($shouldStream: Boolean!) {
        users(limit: 5) @stream(if: $shouldStream, initialCount: 2) {
          id
          name
        }
      }
      """
      
      # With streaming disabled
      result = run_query(query, %{"shouldStream" => false})
      
      # All users should be in initial response
      assert length(result.data["users"]) == 5
      
      # No pending operations
      assert Map.get(result, :pending) == nil
    end
    
    test "streams nested lists" do
      query = """
      query GetUsersWithFriends {
        users(limit: 3) @stream(initialCount: 1, label: "users") {
          id
          name
          friends @stream(initialCount: 1, label: "friends") {
            id
            name
          }
        }
      }
      """
      
      result = run_streaming_query(query)
      
      # Initial response has 1 user with 1 friend
      initial_users = result.initial.data["users"]
      assert length(initial_users) == 1
      assert length(hd(initial_users)["friends"]) == 1
      
      # Multiple pending operations for nested streams
      assert length(result.initial.pending) >= 2
    end
    
    test "streams large lists in batches" do
      query = """
      query GetPosts {
        posts @stream(initialCount: 3, label: "morePosts") {
          id
          title
        }
      }
      """
      
      result = run_streaming_query(query)
      
      # Initial response has 3 posts
      assert length(result.initial.data["posts"]) == 3
      
      # Remaining 17 posts should be streamed in batches
      streamed_batches = result.incremental
      |> Enum.filter(& &1.label == "morePosts")
      
      total_streamed = streamed_batches
      |> Enum.map(& length(&1.items || []))
      |> Enum.sum()
      
      assert total_streamed == 17  # 20 total - 3 initial
    end
    
    test "combines stream with defer" do
      query = """
      query GetPostsWithComments {
        posts(limit: 5) @stream(initialCount: 2, label: "posts") {
          id
          title
          ... @defer(label: "comments") {
            comments {
              id
              text
            }
          }
        }
      }
      """
      
      result = run_streaming_query(query)
      
      # Initial response has 2 posts without comments
      initial_posts = result.initial.data["posts"]
      assert length(initial_posts) == 2
      assert Map.get(hd(initial_posts), "comments") == nil
      
      # Should have both stream and defer pending
      assert length(result.initial.pending) >= 2
      
      # Check for deferred comments
      deferred = Enum.filter(result.incremental, & &1.label == "comments")
      assert length(deferred) > 0
      
      # Check for streamed posts
      streamed = Enum.filter(result.incremental, & &1.label == "posts")
      assert length(streamed) > 0
    end
  end
  
  describe "stream error handling" do
    test "handles errors in streamed items gracefully" do
      query = """
      query GetUsers {
        users @stream(initialCount: 1) {
          id
          name
          invalidField
        }
      }
      """
      
      result = run_streaming_query(query)
      
      # Initial response should have first user (with error for invalid field)
      assert length(result.initial.data["users"]) == 1
      assert result.initial.errors != nil
      
      # Streamed responses should also handle the error
      assert Enum.any?(result.incremental, & &1.errors != nil)
    end
  end
  
  describe "stream with search" do
    test "streams search results" do
      query = """
      query SearchUsers($query: String!) {
        search(query: $query) {
          count
          users @stream(initialCount: 1, label: "searchResults") {
            id
            name
          }
        }
      }
      """
      
      result = run_streaming_query(query, %{"query" => "a"})
      
      # Count should be in initial response
      assert result.initial.data["search"]["count"] > 0
      
      # First user in initial response
      initial_users = result.initial.data["search"]["users"]
      assert length(initial_users) == 1
      
      # Rest streamed
      assert length(result.incremental) > 0
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
    # Use pipeline modifier to enable streaming
    pipeline_modifier = fn pipeline, _options ->
      Absinthe.Pipeline.Incremental.enable(pipeline, 
        enabled: true,
        enable_defer: true,
        enable_stream: true,
        default_stream_batch_size: 3
      )
    end
    
    case Absinthe.run(query, TestSchema, 
      variables: variables,
      pipeline_modifier: pipeline_modifier
    ) do
      {:ok, result} -> 
        # Check if the result has incremental delivery markers
        if Map.has_key?(result, :pending) do
          # This is an incremental response
          %{
            initial: result,
            incremental: simulate_incremental_execution(result.pending)
          }
        else
          # Standard response, simulate as initial only
          %{
            initial: result,
            incremental: []
          }
        end
      error -> 
        error
    end
  end
  
  defp simulate_incremental_execution(pending_operations) do
    # Simulate the execution of pending streamed items
    Enum.map(pending_operations, fn pending ->
      %{
        label: pending.label,
        path: pending.path,
        items: [] # This would contain the streamed items
      }
    end)
  end
  
  defp streaming_pipeline(schema, config) do
    schema
    |> Absinthe.Pipeline.for_document(context: %{incremental_config: config})
    |> replace_resolution_phase()
  end
  
  defp replace_resolution_phase(pipeline) do
    Enum.map(pipeline, fn
      {Absinthe.Phase.Document.Execution.Resolution, opts} ->
        {Absinthe.Phase.Document.Execution.StreamingResolution, opts}
      
      phase ->
        phase
    end)
  end
  
  defp collect_streaming_responses(blueprint) do
    initial = Response.build_initial(blueprint)
    
    streaming_context = get_in(blueprint, [:execution, :context, :__streaming__])
    
    incremental = 
      if streaming_context do
        collect_stream_responses(streaming_context)
      else
        []
      end
    
    %{
      initial: initial,
      incremental: incremental
    }
  end
  
  defp collect_stream_responses(streaming_context) do
    tasks = Map.get(streaming_context, :stream_tasks, [])
    
    Enum.map(tasks, fn task ->
      # Execute the stream task
      result = task.execute.()
      
      %{
        items: result[:items] || [],
        label: task.label,
        path: task.path
      }
    end)
  end
  
  defp collect_streamed_items(incremental_responses) do
    incremental_responses
    |> Enum.flat_map(& &1.items || [])
  end
end