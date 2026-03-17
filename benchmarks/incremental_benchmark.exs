defmodule Absinthe.IncrementalBenchmark do
  @moduledoc """
  Performance benchmarks for incremental delivery features.
  
  Run with: mix run benchmarks/incremental_benchmark.exs
  """
  
  alias Absinthe.Incremental.{Config, Complexity}
  
  defmodule BenchmarkSchema do
    use Absinthe.Schema
    
    @users Enum.map(1..1000, fn i ->
      %{
        id: "user_#{i}",
        name: "User #{i}",
        email: "user#{i}@example.com",
        posts: Enum.map(1..10, fn j ->
          "post_#{i}_#{j}"
        end)
      }
    end)
    
    @posts Enum.map(1..10000, fn i ->
      %{
        id: "post_#{i}",
        title: "Post #{i}",
        content: String.duplicate("Content ", 100),
        comments: Enum.map(1..20, fn j ->
          "comment_#{i}_#{j}"
        end),
        author_id: "user_#{rem(i, 1000) + 1}"
      }
    end)
    
    @comments Enum.map(1..50000, fn i ->
      %{
        id: "comment_#{i}",
        text: "Comment text #{i}",
        author_id: "user_#{rem(i, 1000) + 1}"
      }
    end)
    
    query do
      field :users, list_of(:user) do
        arg :limit, :integer, default_value: 100
        
        # Add complexity calculation
        middleware Absinthe.Middleware.IncrementalComplexity, %{
          max_complexity: 10000
        }
        
        resolve fn args, _ ->
          users = Enum.take(@users, args.limit)
          {:ok, users}
        end
      end
      
      field :posts, list_of(:post) do
        arg :limit, :integer, default_value: 100
        
        resolve fn args, _ ->
          posts = Enum.take(@posts, args.limit)
          {:ok, posts}
        end
      end
    end
    
    object :user do
      field :id, :id
      field :name, :string
      field :email, :string
      
      field :posts, list_of(:post) do
        # Complexity: list type with potential N+1
        complexity fn _, child_complexity ->
          # Base cost of 10 + child complexity
          10 + child_complexity
        end
        
        resolve fn user, _ ->
          posts = Enum.filter(@posts, & &1.author_id == user.id)
          {:ok, posts}
        end
      end
    end
    
    object :post do
      field :id, :id
      field :title, :string
      field :content, :string
      
      field :author, :user do
        complexity 2  # Simple lookup
        
        resolve fn post, _ ->
          user = Enum.find(@users, & &1.id == post.author_id)
          {:ok, user}
        end
      end
      
      field :comments, list_of(:comment) do
        # High complexity for nested list
        complexity fn _, child_complexity ->
          20 + child_complexity
        end
        
        resolve fn post, _ ->
          comments = Enum.filter(@comments, fn c ->
            Enum.member?(post.comments, c.id)
          end)
          {:ok, comments}
        end
      end
    end
    
    object :comment do
      field :id, :id
      field :text, :string
      
      field :author, :user do
        complexity 2
        
        resolve fn comment, _ ->
          user = Enum.find(@users, & &1.id == comment.author_id)
          {:ok, user}
        end
      end
    end
  end
  
  def run do
    IO.puts("\n=== Absinthe Incremental Delivery Benchmarks ===\n")
    
    # Warm up
    warmup()
    
    # Run benchmarks
    benchmark_standard_vs_defer()
    benchmark_standard_vs_stream()
    benchmark_complexity_analysis()
    benchmark_memory_usage()
    benchmark_concurrent_operations()
    
    IO.puts("\n=== Benchmark Complete ===\n")
  end
  
  defp warmup do
    IO.puts("Warming up...")
    
    query = "{ users(limit: 1) { id } }"
    Absinthe.run(query, BenchmarkSchema)
    
    IO.puts("Warmup complete\n")
  end
  
  defp benchmark_standard_vs_defer do
    IO.puts("## Standard vs Defer Performance\n")
    
    standard_query = """
    query {
      users(limit: 50) {
        id
        name
        posts {
          id
          title
          comments {
            id
            text
          }
        }
      }
    }
    """
    
    defer_query = """
    query {
      users(limit: 50) {
        id
        name
        ... @defer(label: "userPosts") {
          posts {
            id
            title
            ... @defer(label: "postComments") {
              comments {
                id
                text
              }
            }
          }
        }
      }
    }
    """
    
    standard_time = measure_time(fn ->
      Absinthe.run(standard_query, BenchmarkSchema)
    end, 100)
    
    defer_time = measure_time(fn ->
      run_with_streaming(defer_query)
    end, 100)
    
    IO.puts("Standard query: #{format_time(standard_time)}")
    IO.puts("Defer query (initial): #{format_time(defer_time)}")
    IO.puts("Improvement: #{format_percentage(standard_time, defer_time)}\n")
  end
  
  defp benchmark_standard_vs_stream do
    IO.puts("## Standard vs Stream Performance\n")
    
    standard_query = """
    query {
      posts(limit: 100) {
        id
        title
        content
      }
    }
    """
    
    stream_query = """
    query {
      posts(limit: 100) @stream(initialCount: 10) {
        id
        title
        content
      }
    }
    """
    
    standard_time = measure_time(fn ->
      Absinthe.run(standard_query, BenchmarkSchema)
    end, 100)
    
    stream_time = measure_time(fn ->
      run_with_streaming(stream_query)
    end, 100)
    
    IO.puts("Standard query: #{format_time(standard_time)}")
    IO.puts("Stream query (initial): #{format_time(stream_time)}")
    IO.puts("Improvement: #{format_percentage(standard_time, stream_time)}\n")
  end
  
  defp benchmark_complexity_analysis do
    IO.puts("## Complexity Analysis Performance\n")
    
    queries = [
      {"Simple", "{ users(limit: 10) { id name } }"},
      {"With defer", "{ users(limit: 10) { id ... @defer { name email } } }"},
      {"With stream", "{ users(limit: 100) @stream(initialCount: 10) { id name } }"},
      {"Nested defer", """
        {
          users(limit: 10) {
            id
            ... @defer {
              posts {
                id
                ... @defer {
                  comments { id }
                }
              }
            }
          }
        }
      """}
    ]
    
    Enum.each(queries, fn {name, query} ->
      time = measure_time(fn ->
        {:ok, blueprint} = Absinthe.Phase.Parse.run(query)
        Complexity.analyze(blueprint)
      end, 1000)
      
      {:ok, blueprint} = Absinthe.Phase.Parse.run(query)
      {:ok, info} = Complexity.analyze(blueprint)
      
      IO.puts("#{name}:")
      IO.puts("  Analysis time: #{format_time(time)}")
      IO.puts("  Complexity: #{info.total_complexity}")
      IO.puts("  Defer count: #{info.defer_count}")
      IO.puts("  Stream count: #{info.stream_count}")
      IO.puts("  Estimated payloads: #{info.estimated_payloads}")
    end)
    
    IO.puts("")
  end
  
  defp benchmark_memory_usage do
    IO.puts("## Memory Usage\n")
    
    query = """
    query {
      users(limit: 100) {
        id
        name
        posts {
          id
          title
          comments {
            id
            text
          }
        }
      }
    }
    """
    
    defer_query = """
    query {
      users(limit: 100) {
        id
        name
        ... @defer {
          posts {
            id
            title
            ... @defer {
              comments {
                id
                text
              }
            }
          }
        }
      }
    }
    """
    
    standard_memory = measure_memory(fn ->
      Absinthe.run(query, BenchmarkSchema)
    end)
    
    defer_memory = measure_memory(fn ->
      run_with_streaming(defer_query)
    end)
    
    IO.puts("Standard query memory: #{format_memory(standard_memory)}")
    IO.puts("Defer query memory: #{format_memory(defer_memory)}")
    IO.puts("Memory savings: #{format_percentage(standard_memory, defer_memory)}\n")
  end
  
  defp benchmark_concurrent_operations do
    IO.puts("## Concurrent Operations\n")
    
    query = """
    query {
      users(limit: 20) @stream(initialCount: 5) {
        id
        name
        ... @defer {
          posts {
            id
            title
          }
        }
      }
    }
    """
    
    concurrency_levels = [1, 5, 10, 20, 50]
    
    Enum.each(concurrency_levels, fn level ->
      time = measure_concurrent(fn ->
        run_with_streaming(query)
      end, level, 10)
      
      IO.puts("Concurrency #{level}: #{format_time(time)}/op")
    end)
    
    IO.puts("")
  end
  
  # Helper functions
  
  defp run_with_streaming(query) do
    config = Config.from_options(enabled: true)
    
    pipeline = 
      BenchmarkSchema
      |> Absinthe.Pipeline.for_document(context: %{incremental_config: config})
      |> Absinthe.Pipeline.Incremental.enable()
    
    Absinthe.Pipeline.run(query, pipeline)
  end
  
  defp measure_time(fun, iterations) do
    times = for _ <- 1..iterations do
      {time, _} = :timer.tc(fun)
      time
    end
    
    Enum.sum(times) / iterations
  end
  
  defp measure_memory(fun) do
    :erlang.garbage_collect()
    before = :erlang.memory(:total)
    
    fun.()
    
    :erlang.garbage_collect()
    after_mem = :erlang.memory(:total)
    
    after_mem - before
  end
  
  defp measure_concurrent(fun, concurrency, iterations) do
    total_time = 
      1..iterations
      |> Enum.map(fn _ ->
        tasks = for _ <- 1..concurrency do
          Task.async(fun)
        end
        
        {time, _} = :timer.tc(fn ->
          Task.await_many(tasks, 30_000)
        end)
        
        time
      end)
      |> Enum.sum()
    
    total_time / (iterations * concurrency)
  end
  
  defp format_time(microseconds) do
    cond do
      microseconds < 1_000 ->
        "#{Float.round(microseconds, 2)}μs"
      microseconds < 1_000_000 ->
        "#{Float.round(microseconds / 1_000, 2)}ms"
      true ->
        "#{Float.round(microseconds / 1_000_000, 2)}s"
    end
  end
  
  defp format_memory(bytes) do
    cond do
      bytes < 1024 ->
        "#{bytes}B"
      bytes < 1024 * 1024 ->
        "#{Float.round(bytes / 1024, 2)}KB"
      true ->
        "#{Float.round(bytes / (1024 * 1024), 2)}MB"
    end
  end
  
  defp format_percentage(original, optimized) do
    improvement = (1 - optimized / original) * 100
    
    if improvement > 0 do
      "#{Float.round(improvement, 1)}% faster"
    else
      "#{Float.round(-improvement, 1)}% slower"
    end
  end
end

# Run the benchmark
Absinthe.IncrementalBenchmark.run()