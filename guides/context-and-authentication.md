# The Context and Authentication

Absinthe context exists to provide shared values to a given document execution.
A common use would be to pass in the current user of a given request. The context
is set at the call to `Absinthe.run`, and cannot be modified over the course of
a given execution.

## Basic Usage

As a basic example let's think about a profile page, where we want the current user
to be able to access basic information about themselves, but not other users.

First we'll need a very basic schema:

```elixir
defmodule MyAppWeb.Schema do
  use Absinthe.Schema

  @fakedb %{
    "1" => %{name: "Bob", email: "bubba@foo.com"},
    "2" => %{name: "Fred", email: "fredmeister@foo.com"},
  }

  query do
    field :profile, :user do
      resolve fn _, _, _ ->
        # How could we get a current user here?
      end
    end
  end

  object :user do
    field :id, :id
    field :name, :string
    field :email, :string
  end
end
```

A query we might want could look like:

```graphql
{
  profile {
    email
  }
}
```

If we're signed in as user 1, we should get only user 1's email, for example:

```json
{
  "profile": {
    "email": "bubba@foo.com"
  }
}
```

In order to set the context, our call to `Absinthe.run/3` should look like:

```elixir
Absinthe.run(document, MyAppWeb.Schema, context: %{current_user: %{id: "1"}})
```

To access this, we need to update our query's resolve function:

```elixir
query do
  field :profile, :user do
    resolve fn _, _, %{context: %{current_user: current_user}} ->
      {:ok, Map.get(@fakedb, current_user.id)}
    end
  end
end
```

And now it works!

## Context and Plugs

When using Absinthe.Plug you don't have direct access to the Absinthe.run call.
Instead, we can use `Absinthe.Plug.put_options/2` to set context values which
Absinthe.Plug will use to pass it along to Absinthe.run.

Setting up your GraphQL context is as simple as writing a plug that inserts the
appropriate values into the connection.

Let's use this mechanism to set our current_user from the previous example via
an authentication header. We will use the same Schema as before.

First, our plug. We'll be checking the connection for the `authorization` header, and calling
out to some unspecified authentication mechanism.

```elixir
defmodule MyAppWeb.Context do
  @behaviour Plug

  import Plug.Conn
  import Ecto.Query, only: [where: 2]

  alias MyApp.{Repo, User}

  def init(opts), do: opts

  def call(conn, _) do
    context = build_context(conn)
    Absinthe.Plug.put_options(conn, context: context)
  end

  @doc """
  Return the current user context based on the authorization header
  """
  def build_context(conn) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
    {:ok, current_user} <- authorize(token) do
      %{current_user: current_user}
    else
      _ -> %{}
    end
  end

  defp authorize(token) do
    User
    |> where(token: ^token)
    |> Repo.one
    |> case do
      nil -> {:error, "invalid authorization token"}
      user -> {:ok, user}
    end
  end

end
```

This plug will use the `authorization` header to lookup the current user. If one
is found, it correctly sets the absinthe context. If you're using Guardian or
some other library that provides utilities for authenticating users you can use
those here too, and just add their output to the context.

If there is no current user it's better to simply not have the `:current_user`
key inside the map, instead of doing `%{current_user: nil}`. This way you an
just pattern match for `%{current_user: user}` in your code and not need to
worry about the nil case.

Using this plug is very simple. If we're just in a normal plug context we can
just make sure it's plugged prior to Absinthe.Plug

```elixir
plug MyAppWeb.Context

plug Absinthe.Plug,
  schema: MyAppWeb.Schema
```

If you're using a Phoenix router, add the context plug to a pipeline.

```elixir
defmodule MyAppWeb.Router do
  use Phoenix.Router

  resource "/pages", MyAppWeb.PagesController

  pipeline :graphql do
    plug MyAppWeb.Context
  end

  scope "/api" do
    pipe_through :graphql

    forward "/", Absinthe.Plug,
      schema: MyAppWeb.Schema
  end
end
```
