# Testing

There are three main approaches to testing GraphQL APIs built with Absinthe:

1. Testing resolver functions, since they do most of work.
2. Testing GraphQL document execution directly via `Absinthe.run/3`, for the bigger picture.
3. Outside-in, testing the full HTTP request/response cycle with [absinthe_plug](https://hexdocs.pm/absinthe_plug/Absinthe.Plug.html).

This guide focuses on the third approach, which we generally recommend since it exercises more
of your application.

## Testing with Absinthe Plug

GraphQL is transport independent, but it's most often served over HTTP. To test HTTP requests with `absinthe` you'll also need `absinthe_plug`. This guide will also assume you're using Phoenix, although 
it is possible to use Absinthe without it (see the [Plug and Phoenix Setup Guide](plug-phoenix.md)).

## Example

Say we want to test the following schema:

```elixir
defmodule MyAppWeb.Schema do
  use Absinthe.Schema

  @fakedb %{
    "1" => %{name: "Bob", email: "bubba@foo.com"},
    "2" => %{name: "Fred", email: "fredmeister@foo.com"}
  }

  query do
    field :user, :user do
      arg :id, non_null(:id)

      resolve &find_user/2
    end
  end

  object :user do
    field :name, :string
    field :email, :string
  end

  defp find_user(%{id: id}, _) do
    {:ok, Map.get(@fakedb, id)}
  end
end
```

Which we have exposed at the `/api` endpoint:

```elixir
defmodule MyAppWeb.Router do
  use Phoenix.Router

  scope "/api" do
    forward "/", Absinthe.Plug, schema: MyAppWeb.Schema
  end
end
```

The test could look something like this:

```elixir
defmodule MyAppWeb.SchemaTest do
  use MyAppWeb.ConnCase

  @user_query """
  query getUser($id: ID!) {
    user(id: $id) {
      name
      email
    }
  }
  """

  test "query: user", %{conn: conn} do
    conn =
      post(conn, "/api", %{
        "query" => @user_query,
        "variables" => %{id: 1}
      })

    assert json_response(conn, 200) == %{
             "data" => %{"user" => %{"email" => "bubba@foo.com", "name" => "Bob"}}
           }
  end
end

```

Phoenix generates the `MyAppWeb.ConnCase` test helper module. This supplies the
`conn` variable containing the request and response.  It also has helper functions 
such as [`post/3`](https://hexdocs.pm/phoenix/Phoenix.ConnTest.html#post/3)
and [`json_response/2`](https://hexdocs.pm/phoenix/Phoenix.ConnTest.html#json_response/2).

The query is stored in the `@user_query` module attribute. We post this document to
the GraphQL endpoint at `/api`, along with a map of variables which will be 
transformed to arguments for the `getUser` query.

The response to the query can then be directly asserted to be a JSON object of the right shape.
