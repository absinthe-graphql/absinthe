# Schema Introspection

You can introspect your schema using `__schema`, `__type`, and `__typename`,
as [described in the specification](https://spec.graphql.org/October2021/#sec-Introspection).

### Examples

Seeing the names of the types in the schema:

```elixir
"""
{
  __schema {
    types {
      name
    }
  }
}
""" |> Absinthe.run(MyAppWeb.Schema)
{:ok,
  %{data: %{
    "__schema" => %{
      "types" => [
        %{"name" => "Boolean"},
        %{"name" => "Float"},
        %{"name" => "ID"},
        %{"name" => "Int"},
        %{"name" => "String"},
        ...
      ]
    }
  }}
}
```

Getting the name of the queried type:

```elixir
"""
{
  profile {
    name
    __typename
  }
}
""" |> Absinthe.run(MyAppWeb.Schema)
{:ok,
  %{data: %{
    "profile" => %{
      "name" => "Joe",
      "__typename" => "Person"
    }
  }}
}
```

Getting the name of the fields for a named type:

```elixir
"""
{
  __type(name: "Person") {
    fields {
      name
      type {
        kind
        name
      }
    }
  }
}
""" |> Absinthe.run(MyAppWeb.Schema)
{:ok,
  %{data: %{
    "__type" => %{
      "fields" => [
        %{
          "name" => "name",
          "type" => %{"kind" => "SCALAR", "name" => "String"}
        },
        %{
          "name" => "age",
          "type" => %{"kind" => "SCALAR", "name" => "Int"}
        },
      ]
    }
  }}
}
```

Note that you may have to nest several depths of `type`/`ofType`, as
type information includes any wrapping layers of [List](https://spec.graphql.org/October2021/#sec-List) and/or [NonNull](https://spec.graphql.org/October2021/#sec-Non-Null).

## Using GraphiQL

The [GraphiQL project](https://github.com/graphql/graphiql) is
"an in-browser IDE for exploring GraphQL."

Absinthe provides GraphiQL via a plug in `absinthe_plug`. See the [Plug and Phoenix Guide](plug-phoenix.md)
for how to install that library. Once installed, usage is simple as:

```elixir
plug Absinthe.Plug.GraphiQL, schema: MyAppWeb.Schema
```

If you want to use it at a particular path (in this case `graphiql` in your Phoenix
router) simply do:

```elixir
# filename: router.ex
forward "/graphiql", Absinthe.Plug.GraphiQL, schema: MyAppWeb.Schema
```

This can be trivially reserved to just the `:dev` elixir environment by doing:

```elixir
# filename: router.ex
if Mix.env == :dev do
  forward "/graphiql", Absinthe.Plug.GraphiQL, schema: MyAppWeb.Schema
end
```

If you'd prefer to use a desktop application, we recommend using the pre-built
[Electron](https://electron.atom.io)-based wrapper application,
[GraphiQL.app](https://github.com/skevy/graphiql-app).
