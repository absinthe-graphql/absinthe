# Subscriptions

When the need arises for near realtime data GraphQL provides subscriptions. We want to support subscriptions that look like

```graphql
subscription {
  newPost {
    id
    name
  }
}
```

Since we had already setup mutations to handle creation of posts we can use that as the event we want to subscribe to. In order to achieve this we have to do a little bit of set up

Let's start by adding `absinthe_phoenix` as a dependency

In `mix.exs`

```elixir
defp deps do
  [
    {:absinthe_phoenix, "~> 1.5"}
    << other deps >>
  ]
```

Then we need to add a supervisor to run some processes for the to handle result broadcasts

In `lib/blog/application.ex`:

```elixir
  children = [
    # other children ...
    {BlogWeb.Endpoint, []}, # this line should already exist
    {Absinthe.Subscription, BlogWeb.Endpoint}, # add this line
    # other children ...
  ]
```

The lets add a configuration to the phoenix endpoint so it can provide some callbacks Absinthe expects, please note while this guide uses phoenix. Absinthe's support for Subscriptions is good enough to be used without websockets even without a browser.

In `lib/blog_web/endpoint.ex`:

```elixir
defmodule BlogWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :blog # this line should already exist
  use Absinthe.Phoenix.Endpoint # add this line

  << rest of the file>>
```

The `PubSub` stuff is now set up, let's configure our sockets

In `lib/blog_web/channels/user_socket.ex`

```elixir
defmodule BlogWeb.UserSocket do
  use Phoenix.Socket # this line should already exist
  use Absinthe.Phoenix.Socket, schema: BlogWeb.Schema # add

  << rest of file>>
```

Let's now configure GraphQL to use this Socket.

In `lib/blog_web/router.ex` :

```elixir
defmodule BlogWeb.Router do
  use BlogWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug BlogWeb.Context
  end

  scope "/api" do
    pipe_through :api

    forward "/graphiql", Absinthe.Plug.GraphiQL,
      schema: BlogWeb.Schema,
      socket: BlogWeb.UserSocket # add this line


    forward "/", Absinthe.Plug,
      schema: BlogWeb.Schema
  end

end
```

Now let/s set up a subscription root object in our Schema to listen for an event. For this subscription we can set it up to listen every time a new post is created.

In `blog_web/schema.ex` :

```elixir
subscription do
  field :new_post, :post do
    config fn _args, _info ->
      {:ok, topic: "*"}
    end
  end
end
```

The `new_post` field is a pretty regular field only new thing here is the `config` macro, this is
here to help us know which clients have subscribed to which fields. Much like WebSockets subscriptions work by allowing t a client to subscribe to a topic.

Topics are scoped to a field and for now we shall use `*` to indicate we care about all the posts, and that's it!

If you ran the request at this moment you would get a nice message telling you that your subscriptions will appear once after they are published but you create a post and alas! no data what cut?

Once a subscription is set up it waits for a target event to get published in order for us to collect this information we need to publish to this subscription

In `blog_web/resolvers/content.ex`:

```elixir
def create_post(_parent, args, %{context: %{current_user: user}}) do
    # Blog.Content.create_post(user, args)
    case Blog.Content.create_post(user, args) do
      {:ok, post} ->
        # add this line in
        Absinthe.Subscription.publish(BlogWeb.Endpoint, post,
        new_post: "*"
        )

        {:ok, post}
      {:error, changeset} ->
        {:ok, "error"}
      end
  end
```

With this, open a tab and run the query at the top of this section. Then open another tab and run a mutation to add a post you should see a result in the other tab have fun.

<img style="box-shadow: 0 0 6px #ccc;" src="assets/tutorial/graphiql_new_post_sub.png" alt=""/>
