# Variables

GraphQL supports query documents that declare variables that can be accepted to
fill-in values. This is a useful mechanism for reusing GraphQL documents --
instead of attempting to interpolate values yourself.

To support variables, simply define them for your query document [as the specification expects](https://facebook.github.io/graphql/#sec-Language.Query-Document.Variables),
and pass in a `variables` option to `Absinthe.run`.

<p class="notice">
  If you're using <a href="/guides/plug-phoenix/">Absinthe.Plug</a>,
  variables are passed in for you automatically after being parsed
  from the query parameters or <code>POST</code> body.
</p>

```elixir
"""
query GetItem($id: ID!) {
  item(id: $id) {
    name
  }
}
"""
|> Absinthe.run(MyApp.Schema, variables: %{"id" => "bar"})

# Result
{:ok, %{data: %{"item" => %{"name" => "Bar"}}}}
```
