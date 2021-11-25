# Understanding Subscriptions

GraphQL subscriptions are a way to have events in the server push data out to clients in real time. The client submits a subscription document that asks for particular data, and then when events happen that document is run against that event and the resulting data is pushed out.

Like queries and mutations, subscriptions are not intrinsically tied to any particular transport, and they're built within Absinthe itself to be able to operate on many different platforms.

At the moment however the most common and fully featured platform that you can run them on with Elixir is via Phoenix channels, so this guide will walk you through the basics of getting them hooked up to a phoenix application.

### Absinthe.Phoenix Setup

Packages you'll need:

```elixir
{:absinthe, "~> 1.5"},
{:absinthe_phoenix, "~> 1.5"},
```

You need to have a working Phoenix pubsub configured. Here is what the default looks like if you create a new Phoenix project:

```elixir
config :my_app, MyAppWeb.Endpoint,
  # ... other config
  pubsub: [name: MyApp.PubSub,
           adapter: Phoenix.PubSub.PG2]
```

In your application supervisor add a line _after_ your existing endpoint supervision
line:

```elixir
    # List all child processes to be supervised
    children = [
      # Start the Ecto repository
      MyAppWeb.Repo,
      # Start the endpoint when the application starts
      MyAppWeb.Endpoint,
      {Absinthe.Subscription, MyAppWeb.Endpoint}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MyAppWeb.Supervisor]
    Supervisor.start_link(children, opts)
```

In older versions of phoenix (pre 1.4) you might see a slightly different syntax,
in which case add Absinthe like this:

```elixir
[
  # other children ...
  MyAppWeb.Repo,
  supervisor(MyAppWeb.Endpoint, []), # this line should already exist
  supervisor(Absinthe.Subscription, MyAppWeb.Endpoint), # add this line
  # other children ...
]
```

Where `MyAppWeb.Endpoint` is the name of your application's phoenix endpoint.

In your `MyAppWeb.Endpoint` module add:

```elixir
use Absinthe.Phoenix.Endpoint
```

For your socket, different configurations are used in `MyAppWeb.UserSocket` depending on what version of
Phoenix you're using.

#### Phoenix 1.3 and 1.4

```elixir
use Absinthe.Phoenix.Socket,
  schema: MyAppWeb.Schema
```

#### Phoenix 1.2

```elixir
  use Absinthe.Phoenix.Socket
  def connect(_params, socket) do
    socket = Absinthe.Phoenix.Socket.put_schema(socket, MyAppWeb.Schema)
    {:ok, socket}
  end
```

Where `MyAppWeb.Schema` is the name of your Absinthe schema module.

### GraphiQL (optional)

If you're using the GraphiQL plug, in your `MyAppWeb.Router`, specify the `socket` option:

```elixir
forward "/graphiql",
        Absinthe.Plug.GraphiQL,
        schema: MyAppWeb.Schema,
        socket: MyAppWeb.UserSocket
```

That is all that's required for setup on the server.

### Setting Options

Options like the context can be configured in the `connect/2` callback in your
socket module.

> Note: The transport macro is deprecated in phoenix 1.4 and can be omitted.

```elixir
defmodule MyAppWeb.UserSocket do
  use Phoenix.Socket
  use Absinthe.Phoenix.Socket,
    schema: MyAppWeb.Schema

  # Deprecated in Phoenix v1.4
  transport :websocket, Phoenix.Transports.WebSocket

  def connect(params, socket) do
    current_user = current_user(params)
    socket = Absinthe.Phoenix.Socket.put_options(socket, context: %{
      current_user: current_user
    })
    {:ok, socket}
  end

  defp current_user(%{"user_id" => id}) do
    MyApp.Repo.get(User, id)
  end

  def id(_socket), do: nil
end
```

### Schema

Here's an example schema that lets you use subscriptions to get notified when a comment
is submitted to a GitHub repository:

```elixir
mutation do
  field :submit_comment, :comment do
    arg :repo_name, non_null(:string)
    arg :content, non_null(:string)

    resolve &Github.submit_comment/3
  end
end

subscription do
  field :comment_added, :comment do
    arg :repo_name, non_null(:string)

    # The topic function is used to determine what topic a given subscription
    # cares about based on its arguments. You can think of it as a way to tell the
    # difference between
    # subscription {
    #   commentAdded(repoName: "absinthe-graphql/absinthe") { content }
    # }
    #
    # and
    #
    # subscription {
    #   commentAdded(repoName: "elixir-lang/elixir") { content }
    # }
    #
    # If needed, you can also provide a list of topics:
    #   {:ok, topic: ["absinthe-graphql/absinthe", "elixir-lang/elixir"]}
    config fn args, _ ->
      {:ok, topic: args.repo_name}
    end

    # this tells Absinthe to run any subscriptions with this field every time
    # the :submit_comment mutation happens.
    # It also has a topic function used to find what subscriptions care about
    # this particular comment
    trigger :submit_comment, topic: fn comment ->
      comment.repository_name
    end

    resolve fn comment, _, _ ->
      # this function is often not actually necessary, as the default resolver
      # for subscription functions will just do what we're doing here.
      # The point is, subscription resolvers receive whatever value triggers
      # the subscription, in our case a comment.
      {:ok, comment}
    end

  end
end
```

Concretely, if client A submits a subscription document:

```graphql
subscription {
  commentAdded(repoName: "absinthe-graphql/absinthe") {
    content
  }
}
```

This tells Absinthe to subscribe client A in the `:comment_added` field on the `"absinthe-graphql/absinthe"` topic, because that's what comes back from the `config` function.

Then, if client B submits a mutation:

```graphql
mutation {
  submitComment(repoName: "absinthe-graphql/absinthe", content: "Great library!") {
     id
  }
}
```

Client B will get the normal response to their mutation, and since they just ask for the `id` that's what they'll get.

Additionally, the `:submit_comment` mutation is configured as a trigger on the `:comment_added` subscription field, so the trigger function is called. That function returns `"absinthe-graphql/absinthe"` because that's the repository name for the comment, and now Absinthe knows it needs to get all subscriptions on the `:comment_added` field that have the `"absinthe-graphql/absinthe"` topic, so client A gets back:

```json
{"data":{"commentAdded":{"content":"Great library!"}}}
```

If you want to publish to this subscription manually (not using triggers in the schema) you can do:

```elixir
Absinthe.Subscription.publish(MyAppWeb.Endpoint, comment, comment_added: "absinthe-graphql/absinthe")
```

If you want to subscribe to mutations from within your application, you can do:

```elixir
{:ok, %{"subscribed" => topic}} = Absinthe.run(subscription_query, MyAppWeb.Schema, context: %{pubsub: MyAppWeb.Endpoint})
MyAppWeb.Endpoint.subscribe(topic)
```

### De-duplicating Updates

By default, Absinthe will resolve each outgoing publish once per individual subscription.  This ensures:

- Different GraphQL documents each receive the different fields they requested
- User-specific updates are sent out, in case `context` contains user-specific data

To improve the scale at which your subscriptions operate, you may tell Absinthe when it is safe to de-duplicate updates.  Simply return a `context_id` from your field's `config` function:

```elixir
subscription do
  field :news_article_published, :article do
    config fn _, _ ->
      {:ok, topic: "*", context_id: "global"}
    end
  end
end
```

Here we return a constant (`"global"`) because our `:article` type doesn't contain any user-specific fields on it.

Given these three active subscriptions:

```graphql
# user 1
subscription {
  newsArticlePublished { content }
}

# user 2
subscription {
  newsArticlePublished { content author }
}

# user 3
subscription {
  newsArticlePublished { content }
}
```

Since we provided a `context_id`, Absinthe will only run two documents per publish to this field:

1. Once for *user 1* and *user 3* because they have the same context ID (`"global"`) and sent the same document.
2. Once for *user 2*.  While *user 2* has the same context ID (`"global"`), they provided a different document, so it cannot be de-duplicated with the other two.
