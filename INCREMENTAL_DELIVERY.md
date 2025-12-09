# Incremental Delivery with @defer and @stream

This document covers the implementation and usage of GraphQL's `@defer` and `@stream` directives in Absinthe for incremental delivery.

## Overview

Incremental delivery allows GraphQL responses to be sent in multiple parts, reducing initial response time and improving user experience. The specification defines two directives:

- **`@defer`**: Defer execution of fragments to reduce initial response latency
- **`@stream`**: Stream list fields incrementally with configurable batch sizes

## Quick Start

### Basic Usage

Add the directives to your queries:

```graphql
query GetUserProfile($userId: ID!) {
  user(id: $userId) {
    id
    name
    # Immediate data above, deferred data below
    ... @defer(label: "profile") {
      email
      profile {
        bio
        avatar
      }
    }
  }
}
```

```graphql
query GetPosts {
  # Stream posts 3 at a time, starting with 2 initially
  posts @stream(initialCount: 2, label: "morePosts") {
    id
    title
    content
  }
}
```

### Schema Configuration

Enable incremental delivery in your schema:

```elixir
defmodule MyApp.Schema do
  use Absinthe.Schema
  
  # Import built-in directives (includes @defer and @stream)
  import_types Absinthe.Type.BuiltIns
  
  query do
    field :user, :user do
      arg :id, non_null(:id)
      resolve &MyApp.Resolvers.get_user/2
    end
    
    field :posts, list_of(:post) do
      resolve &MyApp.Resolvers.list_posts/2
    end
  end
  
  object :user do
    field :id, non_null(:id)
    field :name, non_null(:string)
    field :email, :string
    
    field :profile, :profile do
      # This resolver will be deferred when @defer is used
      resolve fn user, _ ->
        # Simulate expensive operation
        Process.sleep(100)
        {:ok, %{bio: "Bio for #{user.name}", avatar: "avatar.jpg"}}
      end
    end
  end
end
```

### Transport Configuration

#### Phoenix/Plug Setup

```elixir
# router.ex
pipeline :graphql do
  plug :accepts, ["json"]
  plug Absinthe.Plug.Incremental.SSE.Plug
end

scope "/api" do
  pipe_through :graphql
  
  # Standard GraphQL endpoint
  post "/graphql", GraphQLController, :query
  
  # Streaming GraphQL endpoint
  get "/graphql/stream", GraphQLController, :stream
  post "/graphql/stream", GraphQLController, :stream
end
```

```elixir
# graphql_controller.ex
defmodule MyAppWeb.GraphQLController do
  use MyAppWeb, :controller
  
  def query(conn, params) do
    opts = [
      context: %{current_user: get_current_user(conn)}
    ]
    
    Absinthe.Plug.call(conn, {MyApp.Schema, opts})
  end
  
  def stream(conn, _params) do
    # SSE streaming is handled automatically
    Absinthe.Plug.Incremental.SSE.process_query(
      conn,
      MyApp.Schema,
      conn.params["query"],
      conn.params["variables"] || %{},
      context: %{current_user: get_current_user(conn)}
    )
  end
end
```

#### WebSocket Setup (Phoenix Channels)

```elixir
# socket.ex  
defmodule MyAppWeb.UserSocket do
  use Phoenix.Socket
  
  channel "graphql:*", Absinthe.Phoenix.Channel,
    schema: MyApp.Schema,
    incremental: [
      enabled: true,
      default_stream_batch_size: 5
    ]
end
```

## Directive Reference

### @defer

Defers execution of fragments to reduce initial response time.

**Arguments:**
- `if: Boolean` - Conditional deferral (default: true)
- `label: String` - Optional label for tracking (recommended)

**Usage:**
```graphql
{
  user(id: "123") {
    id
    name
    ... @defer(label: "expensiveData") {
      expensiveField
      anotherExpensiveField
    }
  }
}
```

**Response Flow:**
```json
// Initial response
{
  "data": {"user": {"id": "123", "name": "Alice"}},
  "pending": [{"label": "expensiveData", "path": ["user"]}]
}

// Deferred response
{
  "incremental": [{
    "label": "expensiveData",
    "path": ["user"],
    "data": {
      "expensiveField": "value",
      "anotherExpensiveField": "value"
    }
  }]
}

// Completion
{
  "incremental": [],
  "completed": [{"label": "expensiveData", "path": ["user"]}]
}
```

### @stream

Streams list fields incrementally.

**Arguments:**
- `initialCount: Int` - Number of items to include initially (default: 0)
- `if: Boolean` - Conditional streaming (default: true)  
- `label: String` - Optional label for tracking (recommended)

**Usage:**
```graphql
{
  posts @stream(initialCount: 2, label: "morePosts") {
    id
    title
  }
}
```

**Response Flow:**
```json
// Initial response (first 2 items)
{
  "data": {"posts": [{"id": "1", "title": "Post 1"}, {"id": "2", "title": "Post 2"}]},
  "pending": [{"label": "morePosts", "path": ["posts"]}]
}

// Streamed items (remaining items in batches)
{
  "incremental": [{
    "label": "morePosts", 
    "path": ["posts"],
    "items": [{"id": "3", "title": "Post 3"}, {"id": "4", "title": "Post 4"}]
  }]
}

// More streamed items...
{
  "incremental": [{
    "label": "morePosts",
    "path": ["posts"], 
    "items": [{"id": "5", "title": "Post 5"}]
  }]
}

// Completion
{
  "incremental": [],
  "completed": [{"label": "morePosts", "path": ["posts"]}]
}
```

## Advanced Usage

### Combining @defer and @stream

```graphql
query GetUsersWithPosts {
  users @stream(initialCount: 1, label: "moreUsers") {
    id
    name
    ... @defer(label: "userPosts") {
      posts {
        id
        title
      }
    }
  }
}
```

### Nested Streaming

```graphql
query GetPostsWithComments {
  posts @stream(initialCount: 2, label: "morePosts") {
    id
    title
    comments @stream(initialCount: 1, label: "moreComments") {
      id
      text
    }
  }
}
```

### Conditional Directives

```graphql
query GetUserProfile($loadExpensive: Boolean!, $streamPosts: Boolean!) {
  user(id: "123") {
    id
    name
    ... @defer(if: $loadExpensive, label: "profile") {
      profile {
        bio
        avatar
      }
    }
    posts @stream(if: $streamPosts, initialCount: 3, label: "posts") {
      id
      title
    }
  }
}
```

## Configuration

### Global Configuration

```elixir
# config/config.exs
config :absinthe, :incremental,
  enabled: true,
  default_stream_batch_size: 10,
  enable_telemetry: true,
  max_pending_operations: 50
```

### Schema-Level Configuration  

```elixir
defmodule MyApp.Schema do
  use Absinthe.Schema
  
  def middleware(middleware, _field, _object) do
    # Add incremental delivery middleware
    middleware
    |> Absinthe.Middleware.add(Absinthe.Middleware.Incremental)
  end
  
  def plugins do
    [Absinthe.Middleware.Dataloader] ++ 
    Absinthe.Plugin.defaults() ++
    [Absinthe.Plugin.Incremental]
  end
end
```

### Pipeline Configuration

```elixir
# Custom pipeline with incremental delivery
pipeline = 
  MyApp.Schema
  |> Absinthe.Pipeline.for_document(context: context)
  |> Absinthe.Pipeline.Incremental.enable(
    enabled: true,
    default_stream_batch_size: 5,
    enable_defer: true,
    enable_stream: true
  )

{:ok, blueprint, _phases} = Absinthe.Pipeline.run(query, pipeline)
```

## Performance Considerations

### Complexity Analysis

Incremental delivery operations have adjusted complexity costs:

- **@defer**: 1.5x multiplier for deferred fragments
- **@stream**: 2.0x multiplier for streamed fields  
- **Nested operations**: Additional multipliers apply

```elixir
# Configure complexity limits
defmodule MyApp.Schema do
  use Absinthe.Schema
  
  def middleware(middleware, _field, _object) do
    middleware
    |> Absinthe.Middleware.add({Absinthe.Middleware.QueryComplexityAnalysis, 
      max_complexity: 1000,
      incremental_multipliers: %{
        defer: 1.5,
        stream: 2.0,
        nested_defer: 2.5
      }
    })
  end
end
```

### Optimization Strategies

1. **Use appropriate batch sizes**:
   ```elixir
   # For small lists
   posts @stream(initialCount: 5, label: "posts")
   
   # For large datasets  
   posts @stream(initialCount: 10, label: "posts")
   ```

2. **Defer expensive operations**:
   ```graphql
   ... @defer(label: "expensive") {
     expensiveField
     anotherExpensiveField
   }
   ```

3. **Leverage dataloader batching**:
   ```elixir
   # Dataloader continues to batch efficiently across streaming
   field :author, :user do
     resolve &MyApp.DataloaderResolvers.get_author/2
   end
   ```

## Error Handling

### Transport Errors

```elixir
# Errors are delivered in the incremental stream
{
  "incremental": [{
    "label": "userData",
    "path": ["user"],
    "errors": [
      {
        "message": "User not found",
        "locations": [{"line": 5, "column": 7}],
        "path": ["user", "profile"]
      }
    ]
  }]
}
```

### Timeout Handling

```elixir
# config/config.exs
config :absinthe, :incremental,
  operation_timeout: 30_000,  # 30 seconds
  cleanup_interval: 60_000    # 1 minute
```

### Resource Management

The system automatically:
- Cleans up abandoned streaming operations
- Limits concurrent operations per connection
- Provides graceful degradation on errors

## Monitoring and Telemetry

### Telemetry Events

```elixir
# Listen to incremental delivery events
:telemetry.attach_many(
  "incremental-delivery",
  [
    [:absinthe, :incremental, :start],
    [:absinthe, :incremental, :stop],
    [:absinthe, :incremental, :defer],
    [:absinthe, :incremental, :stream]
  ],
  &MyApp.Telemetry.handle_event/4,
  %{}
)
```

### Metrics to Monitor

- Operation latency (initial vs. total)  
- Stream batch sizes and timing
- Error rates per operation type
- Resource usage (memory, connections)

## Troubleshooting

### Common Issues

1. **No incremental responses received**
   - Check transport supports streaming (SSE/WebSocket)
   - Verify schema imports BuiltIns types
   - Confirm incremental delivery is enabled

2. **High memory usage**
   - Reduce stream batch sizes
   - Implement operation timeouts
   - Monitor concurrent operations

3. **Slow performance**
   - Profile resolver execution times
   - Check dataloader batching efficiency
   - Review complexity analysis settings

### Debug Mode

```elixir
# Enable verbose logging
config :absinthe, :incremental,
  debug: true,
  log_level: :debug
```

This will log detailed information about:
- Directive processing
- Stream batch generation
- Transport message flow
- Error conditions