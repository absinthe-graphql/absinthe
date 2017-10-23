---
# Custom Scalars

One of the strengths of GraphQL is its extensibility -- which doesn't end with
its object types, but is present all the way down to the scalar value level.

Sometimes it makes sense to build custom scalar types to better model your
domain. Here's how to do it.

<p class="warning">
  For this example, we'll be building a date-related scalar. In practice, you probably
  want to use one of the already-created date and time scalars that ship with Absinthe as part of
  <a href="https://hexdocs.pm/absinthe/Absinthe.Type.Custom.html#content"><code>Absinthe.Type.Custom</code></a>
</p>

## Defining a scalar

Supporting additional scalar types is as easy as using the `scalar` macro and
providing `parse` and `serialize` functions.

Here's a simple scalar definition:

```elixir
scalar :date, description: "ISO8601 time" do
  parse &parse_date(&1.value)
  serialize &DateTime.to_string(&1)
end

def parse_date(value) do
  case DateTime.from_iso8601(value) do
    {:ok, val, _} -> {:ok, val}
    {:error, _} -> :error
  end
end
```

This creates a new scalar type, `:date` that converts between external string
times in ISO8601 format and internal [DateTime](https://hexdocs.pm/elixir/DateTime.html#t:t/0)
structs.

<p class="notice">
 By default, types defined in Absinthe schemas are automatically given TitleCased
 names for use in GraphQL documents. To give a type a custom name, pass a
 <code>:name</code> option. In this example, our scalar type is automatically assigned <code>Time</code>).
</p>

This method of defining scalars isn't anything special, either. It's exactly
how the built-in scalars `Int`, `String`, `Float`, `ID`, and `Boolean` are defined.

### The parse function

The function provided to `parse` takes the blueprint node from Absinthe and returns a
tuple -- either `{:ok, value}` or `:error`. Any errors during parsing
will be returned to the user as part of the response.

In the `:date` example above, we're wrapping `DateTime.from_iso8601/1` in the `parse_date/1`
function to get the right return values.

### The serialize function

The function provided to `serialize` takes the internal value and serializes it
to the type that will be inserted into the result.

In the `:date` example above, `DateTime.to_string/1` handles this for us,
serializing it to the same format that `parse` expects as input.

### Don't forget your description

Descriptions are especially useful for scalars, as users may not be familiar
with the constraints your `parse` function may place on incoming values.

```elixir
@desc """
The `Date` scalar type represents time values provided in the ISO8601
datetime format (e.g. "2015-06-24T04:50:34Z").
"""
scalar :date, description: "ISO8601 time" do
  parse &parse_date(&1.value)
  serialize &DateTime.to_string(&1)
end

def parse_date(value) do
  case DateTime.from_iso8601(value) do
    {:ok, val, _} -> {:ok, val}
    {:error, _} -> :error
  end
end
```

<p class="warning">
  Don't forget to include descriptions for your types
  (and fields and arguments). Introspection is a key benefit of using GraphQL, and
  you'll thank yourself for helpful descriptions later.
</p>

## As query document variables

Once you have a scalar type defined, you can use it in [query document variables](https://facebook.github.io/graphql/#sec-Language.Query-Document.Variables),
just like any other input type.

Here's a query document that marks a post as read, requiring a non-null `Time` value:

```graphql
mutation MarkPostAsRead($postID: ID!, $when: Time!) {
  markRead(id: $postID, readAt: $when)
}
```

## Further reading

* The `scalar` macro is defined in [Absinthe.Schema.Notation](https://hexdocs.pm/absinthe/Absinthe.Schema.Notation.html#scalar/3).
* Built-in scalar definitions in [Absinthe.Type.BuiltIns.Scalars](https://github.com/absinthe-graphql/absinthe/blob/master/lib/absinthe/type/built_ins/scalars.ex).
* Already existing custom scalar definitions in [Absinthe.Type.Custom](https://hexdocs.pm/absinthe/Absinthe.Type.Custom.html#content).
