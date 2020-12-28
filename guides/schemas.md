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


You may want to refer to the [Absinthe API documentation](https://hexdocs.pm/absinthe/) for more detailed information as you look this over..


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

Now you can use Absinthe to execute a query document. Keep in mind that for
HTTP, you'll probably want to use
[Absinthe.Plug](plug-phoenix.md) instead of executing
GraphQL query documents yourself. Absinthe doesn't know or care about HTTP,
but the `absinthe_plug` project does: it handles the vagaries of interacting
with HTTP GraphQL clients so you don't have to.

If you _were_ executing query documents yourself (let's assume for a local tool),
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

Your schemas can be further customized using the options available to
`Absinthe.Schema.Notation.field/4` to help provide for a richer experience for
your users, customize the field names, or mark fields as deprecated.

```elixir
# filename: myapp/language_schema.ex
@desc "A Language"
object :language do
  field :id, :id
  field :iso_639_1, :string, description: "2 character ISO 639-1 code", name: "iso639"
  field :name, :string, description: "English name of the language"
end
```

## Importing Types

We could also move our type definitions out into a different module, for instance, `MyAppWeb.Schema.Types`, and then use `import_types` in our `MyAppWeb.Schema`:

```elixir
# filename: myapp/schema/types.ex
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

See [Importing Types](importing-types.md) for a full guide to importing types.
