# Understanding Subscriptions

GraphQL subscriptions are a way to have events in the server push data out to clients in real time. The client submits a subscription document that asks for particular data, and then when events happen that document is run against that event and the resulting data is pushed out.

Like queries and mutations, subscriptions are not intrinsically tied to any particular transport, and they're built within Absinthe itself to be able to operate on many different platforms.

At the moment however the most common and fully featured platform that you can run them on with Elixir is via Phoenix channels, so this guide will walk you through the basics of getting them hooked up to a phoenix application.

### Absinthe.Phoenix Setup

Libraries you'll need:

```elixir
{:absinthe, "~> 1.4.0"},
{:absinthe_phoenix, "~> 1.4.0"},
```


You need to have a working phoenix pubsub configured. Here is what the default looks like if you create a new phoenix project:

```elixir
config :my_app, MyAppWeb.Endpoint,
  # ... other config
  pubsub: [name: MyApp.PubSub,
           adapter: Phoenix.PubSub.PG2]
```

In your application supervisor add a line AFTER your existing endpoint supervision
line:

```elixir
[
  # other children ...
  supervisor(MyAppWeb.Endpoint, []), # this line should already exist
  supervisor(Absinthe.Subscription, [MyAppWeb.Endpoint]), # add this line
  # other children ...
]
```

Where `MyAppWeb.Endpoint` is the name of your application's phoenix endpoint.

In your `MyApp.Web.Endpoint` module add:
```elixir
use Absinthe.Phoenix.Endpoint
```

In your socket add:

#### Phoenix 1.3
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

That is all that's required for setup on the server.

### Setting Options

Options like the context can be configured in the `def connect` callback of your
socket

```elixir
defmodule GitHunt.Web.UserSocket do
  use Phoenix.Socket
  use Absinthe.Phoenix.Socket,
    schema: MyApp.Web.Schema

  transport :websocket, Phoenix.Transports.WebSocket

  def connect(params, socket) do
    current_user = current_user(params)
    socket = Absinthe.Phoenix.Socket.put_opts(socket, context: %{
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

Example schema that lets you use subscriptions to get notified when a comment
is submitted to a github repo.

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

Concretely, if client A submits a subscription doc:

```graphql
subscription {
  commentAdded(repoName: "absinthe-graphql/absinthe") {
    content
  }
}
```

this tells Absinthe to subscribe client A in the `:comment_added` field on the `"absinthe-graphql/absinthe"` topic, because that's what comes back from the `setup` function.

Then if client B submits a mutation:

```graphql
mutation {
  submitComment(repoName: "absinthe-graphql/absinthe", content: "Great library!") {
     id
  }
}
```

Client B will get the normal response to their mutation, and since they just ask for the `id` that's what they'll get.

Additionally, the `:submit_comment` mutation is configured as a trigger on the `:commented_added` subscription field, so the trigger function is called. That function returns `"absinthe-graphql/absinthe"` because that's the repository name the comment was on, and now Absinthe knows it needs to get all subscriptions on the `:comment_added` field that have the `"absinthe-graphql/absinthe"` topic, so client A gets back

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

This guide is up to date, but incomplete. Stay tuned for more content!
