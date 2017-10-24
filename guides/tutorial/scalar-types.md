# Scalar Types

It would be nice if our blog posts had a `posted_at` time. This would
be something we could both send as part of our CreatePost mutation,
and also retrieve in a query.

```graphql
mutation CreatePost {
  post(title: "Second", body: "We're off to a great start!", postedAt: "2016-01-19T16:07:37Z") {
    id
    postedAt
  }
}
```

Here we have a small conundrum. While GraphQL strings have an obvious
counterpart in elixir strings, time in Elixir is often represented by
something like a Timex struct. We could handle this in our resolvers
by manually serializing or deserializing the time data. Fortunately
however GraphQL provides a better way via allowing us to build
additional
[Scalar](Absinthe.Type.Scalar.html) types.

Let's define our time type in `web/schema/types.ex`:

```elixir
scalar :time, description: "ISOz time" do
  parse &Timex.DateFormat.parse(&1.value, "{ISOz}")
  serialize &Timex.DateFormat.format!(&1, "{ISOz}")
end
```

Our post should now look like this in `web/schema/types.ex`:

```elixir
object :post do
  field :title, :string
  field :body, :string
  field :posted_at, :time
end
```

And our mutation in the schema, `web/schema.ex` should look like:

```elixir
mutation do
  field :post, type: :post do
    arg :title, non_null(:string)
    arg :body, non_null(:string)
    arg :posted_at, non_null(:time)
    resolve &Blog.PostResolver.create/2
  end
end
```

When `posted_at` is passed as an argument, the parse function we
defined in our `:time` type will be called and it will automatically
arrive in our resolver as a `Timex.DateTime` struct! Similarly, when
we return the `posted_at` field the `Timex.DateTime` struct will be
serialized back to a string for easy JSON representation.

> Note that Absinthe now comes complete with date types as part of the
> [Absinthe.Type.Custom](Absinthe.Type.Custom.html) module, using the
> date and datetime that are part of Elixir's standard library.
