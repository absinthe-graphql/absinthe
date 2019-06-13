# Testing Absinthe

GraphQL is transport independent, although most often it will be served over
HTTP. So, to test Absinthe we'll also need [`Absinthe.Plug`](./plug-phoenix.html) as a transport.

We could test documents directly with `Absinthe.run/3`. However, when in this guide
we use `Absinthe.Plug` as it has minimal 
overhead and will oftentimes also setup the [context](./context-and-authentication.html#context-and-plugs)
of the connection, therefore it provides a more
comprehensive coverage. The following example therefore uses `Absinthe.Plug` to
test a resolver. 

The example also assumes that you run `Absinthe` within `Phoenix`, although
it should not differ a lot from using `Absinthe` with just `Plug`.


## Example

Say we want to test the following schema.

```elixir
defmodule MyAppWeb.Schema do
  use Absinthe.Schema

  @fakedb %{
    "1" => %{name: "Bob", email: "bubba@foo.com"},
    "2" => %{name: "Fred", email: "fredmeister@foo.com"}
  }

  query do
    field :user, :user do
      arg(:id, non_null(:id))

      resolve(&find_user/2)
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

Which we have exposed at the "/api" endpoint:

```elixir
defmodule MyAppWeb.Router do
  use Phoenix.Router

  scope "/api" do
    forward "/", Absinthe.Plug, schema: MyAppWeb.Schema
  end
end
```

The test will look something like this

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

  test "user resolver", %{conn: conn} do
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

Phoenix generates the `MyAppWeb.ConnCase` testhelper module. This supplies the
`conn` variable containing the request and response.  It also has helper functions 
such as [`post/3`](https://hexdocs.pm/phoenix/Phoenix.ConnTest.html#post/3)
and [`json_response/2`](https://hexdocs.pm/phoenix/Phoenix.ConnTest.html#json_response/2).

The query is stored in the `@user_query` module attribute. We post this document to
the GraphQL endpoint at "/api", along with a map of variables which will be 
transformed to arguments to the `getUser` query.

The response to the query is then asserted to be json and of the right shape.

