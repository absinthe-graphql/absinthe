# Using Document Variables

GraphQL supports query documents that declare variables that can be accepted to fill-in values. This is a useful mechanism for reusing GraphQL documents---instead of attempting to interpolate values yourself.

- To support variables, simply define them for your query document [as the specification expects](https://spec.graphql.org/October2021/#sec-Language.Variables), and pass in a `variables` option to `Absinthe.run`.
- If you're using [absinthe_plug](https://github.com/absinthe-graphql/absinthe_plug), variables are passed in for you automatically after being parsed
from the query parameters or `POST` body.

Here's an example of defining a non-nullable variable, `id`, in a document and then executing the document with a value for the variable:

```elixir
"""
query GetItem($id: ID!) {
  item(id: $id) {
    name
  }
}
"""
|> Absinthe.run(MyAppWeb.Schema, variables: %{"id" => "bar"})

# Result
{:ok, %{data: %{"item" => %{"name" => "Bar"}}}}
```
