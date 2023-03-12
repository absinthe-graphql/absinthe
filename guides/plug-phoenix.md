# Plug and Phoenix Setup

First, install Absinthe.Plug and a JSON codec of your choice,
eg, [Jason](https://hex.pm/packages/jason):

```elixir
# filename: mix.exs
def deps do
  [
    {:absinthe_plug, "~> 1.5"},
    {:jason, "~> 1.0"},
  ]
end
```

## Plug

To use, simply `plug` Absinthe.Plug in your pipeline.

```elixir
plug Absinthe.Plug,
  schema: MyAppWeb.Schema
```

If you are going to support content types other than simply `application/graphql`
you should plug Absinthe.Plug after Plug.Parsers.

```elixir
plug Plug.Parsers,
  parsers: [:urlencoded, :multipart, :json, Absinthe.Plug.Parser],
  json_decoder: Jason

plug Absinthe.Plug,
  schema: MyAppWeb.Schema
```

For more information on how the content types work, see [General Usage](#general-usage).

## Phoenix

If your entire API is going to be based on GraphQL, we recommend simply plugging
Absinthe.Plug in at the bottom of your endpoint, and removing your router altogether.

```elixir
defmodule MyApp.Endpoint do
  use Phoenix.Endpoint, otp_app: :my_app

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason

  plug Absinthe.Plug,
    schema: MyAppWeb.Schema
end
```

If you want only `Absinthe.Plug` to serve a particular route, configure your router
like:

```elixir
defmodule MyAppWeb.Router do
  use Phoenix.Router

  resource "/pages", MyAppWeb.PagesController

  forward "/api", Absinthe.Plug,
    schema: MyAppWeb.Schema
end
```

Now Absinthe.Plug will only serve GraphQL from the `/api` url.

## Absinthe Context

`Absinthe.Plug` will pass any values found inside `conn.private[:absinthe][:context]`
on to `Absinthe.run` as the context. This is how you should handle logic that
uses headers -- most notably, Authentication.

For more information, see the [Context](context-and-authentication.md) guide.

## GraphiQL

See the [absinthe_plug](https://github.com/absinthe-graphql/absinthe_plug)
project and the GraphiQL portion of the [Introspection](introspection.md) guide to
learn how to use the built-in `Absinthe.Plug.GraphiQL` plug.

## General Usage

This plug supports requests in a number of ways:

### Via a GET

With a query string:

```
?query=query+GetItem($id:ID!){item(id:$id){name}}&variables={id:"foo"}
```

Due to [varying limits on the maximum size of URLs](https://stackoverflow.com/questions/417142/what-is-the-maximum-length-of-a-url-in-different-browsers),
we recommend using one of the POST options below instead, putting the `query` into the body of the request.

### Via an `application/json` POST

With a POST body:

```json
{
  "query": "query GetItem($id: ID!) { item(id: $id) { name } }",
  "variables": {
    "id": "foo"
  }
}
```

(We could also pull either `query` or `variables` out to the query string, just
as in the [GET example](#via-a-get).)

### Via an `application/graphql` POST

With a query string:

`?variables={id:"foo"}`

And a POST body:

```graphql
query GetItem($id: ID!) {
  item(id: $id) {
    name
  }
}
```

### HTTP API

How clients interact with the plug over HTTP is designed to closely match that
of the official
[express-graphql](https://github.com/graphql/express-graphql) middleware.

In the [example above](#example), we went over the various ways to
make a request, but here are the details:

Once installed at a path, the plug will accept requests with the
following parameters:

  * `query` - A string GraphQL document to be executed.

  * `variables` - The runtime values to use for any GraphQL query variables
    as a JSON object.

  * `operationName` - If the provided `query` contains multiple named
    operations, this specifies which operation should be executed. If not
    provided, a 400 error will be returned if the `query` contains multiple
    named operations.

The plug will first look for each parameter in the query string, eg:

```
/graphql?query=query+getUser($id:ID){user(id:$id){name}}&variables={"id":"4"}
```

If not found in the query string, it will look in the POST request body, using
a strategy based on the `Content-Type` header.

For content types `application/json` and `application/x-www-form-urlencoded`,
configure `Plug.Parsers` (or equivalent) to parse the request body before `Absinthe.Plug`, eg:

```elixir
plug Plug.Parsers,
  parsers: [:urlencoded, :multipart, :json],
  pass: ["*/*"],
  json_decoder: Jason
```

For `application/graphql`, the POST body will be parsed as GraphQL query string,
which provides the `query` parameter. If `variables` or `operationName` are
needed, they should be passed as part of the

## Configuration Notes

As a plug, `Absinthe.Plug` requires very little configuration. If you want to support
`application/x-www-form-urlencoded` or `application/json` you'll need to plug
`Plug.Parsers` first.


```elixir
plug Plug.Parsers,
  parsers: [:urlencoded, :multipart, :json],
  pass: ["*/*"],
  json_decoder: Jason

plug Absinthe.Plug,
  schema: MyApp.Linen.Schema
```

`Absinthe.Plug` requires a `schema:` config.

It also takes several options. See [the documentation](https://hexdocs.pm/absinthe_plug/Absinthe.Plug.html#init/1)
for the full listing.

## Inside Phoenix controllers

You can use GraphQL as the datasource for your Phoenix controllers. For this 
you'll need to add `absinthe_phoenix` to your dependencies. See [Absinthe Phoenix](https://github.com/absinthe-graphql/absinthe_phoenix) for installation instructions.

```elixir
@graphql """
  query ($filter: UserFilter) {
    users(filter: $filter, limit: 10)
  }
"""
def index(conn, %{data: data}) do
  render conn, "index.html", data
end
```
The results of the query are now available in the "index.html" template. For
more information, see [`Absinthe.Phoenix.Controller`](https://hexdocs.pm/absinthe_phoenix/Absinthe.Phoenix.Controller.html)
