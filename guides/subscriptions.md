# Understanding Subscriptions


Libraries you'll need:

```elixir
{:absinthe, github: "absinthe-graphql/absinthe"},
{:absinthe_phoenix, github: "absinthe-graphql/absinthe_phoenix"},
```

In your application supervisor add this line AFTER your existing endpoint supervision
line:

```elixir
supervisor(Absinthe.Subscription, [MyApp.Web.Endpoint]),
```

Where `MyApp.Web.Endpoint` is the name of your application's phoenix endpoint.

In your `MyApp.Web.Endpoint` module add:
```elixir
use Absinthe.Phoenix.Endpoint
```

In your socket add:

#### Phoenix 1.3
```elixir
use Absinthe.Phoenix.Socket,
  schema: MyApp.Web.Schema
```

#### Phoenix 1.2

```elixir
  use Absinthe.Phoenix.Socket
  def connect(params, socket) do
    current_user = current_user(params)
    socket = Absinthe.Phoenix.Socket.put_schema(socket, MyApp.Web.Schema)
    {:ok, socket}
  end
```

Where `MyApp.Web.Schema` is the name of your Absinthe schema module.

That is all that's required for setup on the server.

### GraphiQL

At this time only the simpler GraphiQL interface supports subscriptions. To use
them, just add a `:socket` option to your graphiql config:

```elixir
forward "/graphiql", Absinthe.Plug.GraphiQL,
  schema: JLR.Web.Schema,
  socket: JLR.Web.UserSocket,
  interface: :simple
```

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

### JavaScript Clients

| Name  | Framework      | Status |
| :---: | -------------- | ------ |
| [absinthe-phoenix-js](https://github.com/absinthe-graphql/absinthe-phoenix-js)  | (None) | Official |
| [apollo-phoenix-websocket](https://github.com/vic/apollo-phoenix-websocket) | Apollo | Community (Maintained by [@vic](https://github.com/vic)) |
| ? | Relay (Classic) | Missing (Please contribute!) |
| ? | Relay (Modern) | Missing (Please contribute!) |

### Schema

Example schema that lets you use subscriptions to get notified when a comment
is submitted to a github repo.

See https://hexdocs.pm/absinthe/1.4.0-beta.1/Absinthe.Schema.html#subscription/2
for more details on setting up subscriptions in your schema.

```elixir
mutation do
  field :submit_comment, :comment do
    arg :repo_full_name, non_null(:string)
    arg :comment_content, non_null(:string)

    resolve &Github.submit_comment/3
  end
end

subscription do
  field :comment_added, :comment do
    arg :repo_full_name, non_null(:string)

    # The topic function is used to determine what topic a given subscription
    # cares about based on its arguments. You can think of it as a way to tell the
    # difference between
    # subscription {
    #   commentAdded(repoFullName: "absinthe-graphql/absinthe") { content }
    # }
    #
    # and
    #
    # subscription {
    #   commentAdded(repoFullName: "elixir-lang/elixir") { content }
    # }
    config fn args, _ ->
      {:ok, topic: args.repo_full_name}
    end

    # this tells Absinthe to run any subscriptions with this field every time
    # the :submit_comment mutation happens.
    # It also has a topic function used to find what subscriptions care about
    # this particular comment
    trigger :submit_comment, topic: fn comment ->
      comment.repository_name
    end

    resolve fn %{comment_added: comment}, _, _ ->
      # this function is often not actually necessary, as the default resolver
      # will pull the root value off properly.
      # It's only here to show what happens.
      {:ok, comment}
    end

  end
end
```
