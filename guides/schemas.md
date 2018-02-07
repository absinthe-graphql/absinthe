# Writing Schemas

A GraphQL API starts by building a schema. Using Absinthe, schemas are normal
modules that use `Absinthe.Schema`.

Here's a schema that supports looking up an item by ID:

```elixir
# filename: myapp/schema.ex
defmodule MyAppWeb.Schema do

  use Absinthe.Schema

  # Example data
  @items %{
    "foo" => %{id: "foo", name: "Foo"},
    "bar" => %{id: "bar", name: "Bar"}
  }

  query do
    field :item, :item do
      arg :id, non_null(:id)
      resolve fn %{id: item_id}, _ ->
        {:ok, @items[item_id]}
      end
    end
  end

end
```

<p class="notice">
  You may want to refer to the <a href="https://hexdocs.pm/absinthe/">Absinthe API
  documentation</a> for more detailed information as you look this over..
</p>

Some macros and functions used here that are worth mentioning, pulled in automatically from
`Absinthe.Schema.Notation` by `use Absinthe.Schema`:

- `query` - Defines the root query object. It's like using `object` but with
   nice defaults. There is a matching `mutation` macro as well.
- `field` - Defines a field in the enclosing `object`, `input_object`, or `interface`.
- `arg` - Defines an argument in the enclosing `field` or `directive`.
- `resolve` - Sets the resolve function for the enclosing `field`.

You'll notice we mention some types being referenced: `:item` and `:id`. `:id`
is a built-in scalar type (like `:string`, `:boolean`, and others), but `:item`
we need to define ourselves.

We can do it in the same `MyAppWeb.Schema` module, using the `object` macro defined by `Absinthe.Schema.Notation`:

```elixir
# filename: myapp/schema.ex
@desc "An item"
object :item do
  field :id, :id
  field :name, :string
end
```

Now, you can use Absinthe to execute a query document. Keep in mind that for
HTTP, you'll probably want to use
[Absinthe.Plug](plug-phoenix.html) instead of executing
GraphQL query documents yourself. Absinthe doesn't know or care about HTTP,
but the `absinthe_plug` project does -- and handles the vagaries of interacting
with HTTP GraphQL clients so you don't have to.

If you _were_ executing query documents yourself (lets assume for a local tool),
it would go something like this:

```elixir
"""
{
  item(id: "foo") {
    name
  }
}
"""
|> Absinthe.run(MyAppWeb.Schema)

# Result
{:ok, %{data: %{"item" => %{"name" => "Foo"}}}}
```

## Importing Types

We could also move our type definitions out into a different module, for instance, `MyAppWeb.Schema.Types`, and then use `import_types` in our `MyAppWeb.Schema`:

```elixir
# filename: myapp/schema.ex
defmodule MyAppWeb.Schema.Types do
  use Absinthe.Schema.Notation

  object :item do
    field :id, :id
    field :name, :string
  end

  # ...

end

# filename: myapp/schema.ex
defmodule MyAppWeb.Schema do
  use Absinthe.Schema

  import_types MyAppWeb.Schema.Types

  # ...

end
```

It's a nice way of separating the top-level `query` and `mutation` information,
which define the surface area of the API, with the actual types that it uses.

See [Importing Types](importing-types.html) for a full guide to importing types.
