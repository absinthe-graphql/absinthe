# Incremental Delivery

GraphQL's incremental delivery allows responses to be sent in multiple parts, reducing initial response time and improving user experience. Absinthe supports this through the `@defer` and `@stream` directives.

## Overview

Incremental delivery splits GraphQL responses into:

- **Initial response**: Fast delivery of immediately available data
- **Incremental responses**: Subsequent delivery of deferred/streamed data

This pattern is especially useful for:
- Complex queries with expensive fields
- Large lists that can be paginated
- Progressive data loading in UIs

## Installation

Incremental delivery is built into Absinthe 1.7+ and requires no additional dependencies.

```elixir
def deps do
  [
    {:absinthe, "~> 1.7"},
    {:absinthe_phoenix, "~> 2.0"}  # For WebSocket transport
  ]
end
```

## Basic Usage

### The @defer Directive

The `@defer` directive allows you to defer execution of fragments:

```elixir
# In your schema
query do
  field :user, :user do
    arg :id, non_null(:id)
    resolve &MyApp.Resolvers.user_by_id/2
  end
end

object :user do
  field :id, non_null(:id)
  field :name, non_null(:string)
  
  # These fields will be resolved when deferred
  field :email, :string
  field :profile, :profile
end
```

```graphql
query GetUser($userId: ID!) {
  user(id: $userId) {
    id
    name
    
    # This fragment will be deferred
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

**Response sequence:**

1. Initial response:
```json
{
  "data": {
    "user": {
      "id": "123",
      "name": "John Doe"
    }
  },
  "pending": [
    {"id": "0", "label": "profile", "path": ["user"]}
  ]
}
```

2. Deferred response:
```json
{
  "id": "0",
  "data": {
    "email": "john@example.com",
    "profile": {
      "bio": "Software Engineer",
      "avatar": "avatar.jpg"
    }
  }
}
```

### The @stream Directive

The `@stream` directive allows you to stream list fields:

```elixir
# In your schema
query do
  field :posts, list_of(:post) do
    resolve &MyApp.Resolvers.all_posts/2
  end
end

object :post do
  field :id, non_null(:id)
  field :title, non_null(:string)
  field :content, :string
end
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

**Response sequence:**

1. Initial response with first 2 posts:
```json
{
  "data": {
    "posts": [
      {"id": "1", "title": "First Post", "content": "..."},
      {"id": "2", "title": "Second Post", "content": "..."}
    ]
  },
  "pending": [
    {"id": "0", "label": "morePosts", "path": ["posts"]}
  ]
}
```

2. Streamed responses with remaining posts:
```json
{
  "id": "0",
  "items": [
    {"id": "3", "title": "Third Post", "content": "..."},
    {"id": "4", "title": "Fourth Post", "content": "..."},
    {"id": "5", "title": "Fifth Post", "content": "..."}
  ]
}
```

## Enabling Incremental Delivery

### Using Pipeline Modifier

Enable incremental delivery using a pipeline modifier:

```elixir
# In your controller/resolver
def execute_query(query, variables) do
  pipeline_modifier = fn pipeline, _options ->
    Absinthe.Pipeline.Incremental.enable(pipeline, 
      enabled: true,
      enable_defer: true,
      enable_stream: true
    )
  end
  
  Absinthe.run(query, MyApp.Schema, 
    variables: variables,
    pipeline_modifier: pipeline_modifier
  )
end
```

### Configuration Options

```elixir
config = [
  # Feature flags
  enabled: true,
  enable_defer: true,
  enable_stream: true,
  
  # Resource limits
  max_concurrent_streams: 100,
  max_stream_duration: 30_000,  # 30 seconds
  max_memory_mb: 500,
  
  # Batching settings
  default_stream_batch_size: 10,
  max_stream_batch_size: 100,
  
  # Transport settings
  transport: :auto,  # :auto | :sse | :websocket
  
  # Error handling
  error_recovery_enabled: true,
  max_retry_attempts: 3
]

Absinthe.Pipeline.Incremental.enable(pipeline, config)
```

## Transport Integration

### Phoenix WebSocket

```elixir
# In your Phoenix socket
def handle_in("doc", payload, socket) do
  pipeline_modifier = fn pipeline, _options ->
    Absinthe.Pipeline.Incremental.enable(pipeline, enabled: true)
  end
  
  case Absinthe.run(payload["query"], MyApp.Schema, 
    variables: payload["variables"],
    pipeline_modifier: pipeline_modifier
  ) do
    {:ok, %{data: data, pending: pending}} ->
      push(socket, "data", %{data: data})
      
      # Handle incremental responses
      handle_incremental_responses(socket, pending)
      
    {:ok, %{data: data}} ->
      push(socket, "data", %{data: data})
  end
  
  {:noreply, socket}
end

defp handle_incremental_responses(socket, pending) do
  # Implementation depends on your transport
  # This would handle the streaming of deferred/streamed data
end
```

### Server-Sent Events (SSE)

```elixir
# In your Phoenix controller
def stream_query(conn, params) do
  conn = conn
    |> put_resp_header("content-type", "text/event-stream")
    |> put_resp_header("cache-control", "no-cache")
    |> send_chunked(:ok)
  
  pipeline_modifier = fn pipeline, _options ->
    Absinthe.Pipeline.Incremental.enable(pipeline, enabled: true)
  end
  
  case Absinthe.run(params["query"], MyApp.Schema,
    variables: params["variables"],
    pipeline_modifier: pipeline_modifier
  ) do
    {:ok, result} ->
      send_sse_event(conn, "data", result.data)
      
      if Map.has_key?(result, :pending) do
        handle_sse_streaming(conn, result.pending)
      end
  end
end
```

## Advanced Usage

### Conditional Deferral

Use the `if` argument to conditionally defer:

```graphql
query GetUser($userId: ID!, $includeProfile: Boolean = false) {
  user(id: $userId) {
    id
    name
    
    ... @defer(if: $includeProfile, label: "profile") {
      email
      profile { bio }
    }
  }
}
```

### Nested Deferral

Defer nested fragments:

```graphql
query GetUserData($userId: ID!) {
  user(id: $userId) {
    id
    name
    
    ... @defer(label: "level1") {
      email
      posts {
        id
        title
        
        ... @defer(label: "level2") {
          content
          comments { text }
        }
      }
    }
  }
}
```

### Complex Streaming

Stream with different batch sizes:

```graphql
query GetDashboard {
  # Stream recent posts quickly
  recentPosts @stream(initialCount: 3, label: "recentPosts") {
    id
    title
  }
  
  # Stream popular posts more slowly  
  popularPosts @stream(initialCount: 1, label: "popularPosts") {
    id
    title
    metrics { views }
  }
}
```

## Error Handling

Incremental delivery handles errors gracefully:

```elixir
# Errors in deferred fragments don't affect initial response
{:ok, %{
  data: %{"user" => %{"id" => "123", "name" => "John"}},
  pending: [%{id: "0", label: "profile"}]
}}

# Later, deferred response with error
{:error, %{
  id: "0", 
  errors: [%{message: "Profile not found", path: ["user", "profile"]}]
}}
```

## Performance Considerations

### Batching with Dataloader

Incremental delivery works with Dataloader:

```elixir
# The dataloader will batch across all streaming operations
field :posts, list_of(:post) do
  resolve dataloader(Blog, :posts_by_user_id)
end
```

### Resource Management

Configure limits to prevent resource exhaustion:

```elixir
config = [
  max_concurrent_streams: 50,
  max_stream_duration: 30_000,
  max_memory_mb: 200
]
```

### Monitoring

Use telemetry for observability:

```elixir
# Attach telemetry handlers
:telemetry.attach_many(
  "incremental-delivery",
  [
    [:absinthe, :incremental, :start],
    [:absinthe, :incremental, :stop],
    [:absinthe, :incremental, :defer, :start],
    [:absinthe, :incremental, :stream, :start]
  ],
  &MyApp.Telemetry.handle_event/4,
  nil
)
```

## Relay Integration

Incremental delivery works seamlessly with Relay connections:

```graphql
query GetUserPosts($userId: ID!, $first: Int) {
  user(id: $userId) {
    id
    name
    
    posts(first: $first) @stream(initialCount: 5, label: "morePosts") {
      edges {
        node { id title }
        cursor
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
}
```

## Testing

Test incremental delivery in your test suite:

```elixir
test "incremental delivery with @defer" do
  query = """
  query GetUser($id: ID!) {
    user(id: $id) {
      id
      name
      ... @defer(label: "profile") {
        email
      }
    }
  }
  """
  
  pipeline_modifier = fn pipeline, _options ->
    Absinthe.Pipeline.Incremental.enable(pipeline, enabled: true)
  end
  
  assert {:ok, result} = Absinthe.run(query, MyApp.Schema, 
    variables: %{"id" => "123"},
    pipeline_modifier: pipeline_modifier
  )
  
  # Check initial response
  assert result.data["user"]["id"] == "123"
  assert result.data["user"]["name"] == "John"
  refute Map.has_key?(result.data["user"], "email")
  
  # Check pending operations
  assert [%{label: "profile"}] = result.pending
end
```

## Migration Guide

Existing queries work without changes. To add incremental delivery:

1. **Identify expensive fields** that can be deferred
2. **Find large lists** that can be streamed  
3. **Add directives gradually** to minimize risk
4. **Configure transport** to handle streaming responses
5. **Add monitoring** to track performance improvements

## See Also

- [Subscriptions](subscriptions.md) for real-time data
- [Dataloader](dataloader.md) for efficient data fetching
- [Telemetry](telemetry.md) for observability
- [GraphQL Incremental Delivery Spec](https://graphql.org/blog/2020-12-08-defer-stream)