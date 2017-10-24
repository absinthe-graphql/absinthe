# Ecto Best Practices

> Much of this guide is out-of-date with recent additions to the [absinthe_ecto](https://hex.pm/packages/absinthe_ecto)
> package.
>
> You can help! Please edit `guides/ecto.md` and submit a [pull request](https://github.com/absinthe-graphql/absinthe/pulls).

## Avoiding N+1 Queries

In general, you want to make sure that when accessing Ecto associations that you
preload the data in the top level resolver functions to avoid N+1 queries.

Imagine this scenario: You have posts and users. A Post has an author field, which
returns a user. You want to list all posts, and get the name of their author:

```graphql
{
  posts {
    author {
      name
    }
  }
}
```

If you write your schema like this, you're going to have a _bad_ time due to issues with _N + 1_:

```elixir
object :post do
  @desc "Author of the post"
  field :author, :user do
    resolve fn post, _, _ ->
      author =
        post
        |> Ecto.assoc(:author)
        |> Repo.one

      {:ok, author}
    end
  end
end

query do
  field :posts, list_of(:post) do
    resolve fn _, _ ->
      {:ok, Post |> Repo.all}
    end
  end
end
```

What this schema will do when presented with the GraphQL query is
run `Post |> Repo.all`, which will retrieve _N_ posts. Then for each
post it will resolve child fields, which runs our `Repo.one` query
function, resulting in _N+1_ calls to the database.

Instead, use batching! At the moment (Oct-31-2016) Batching is pretty new, so we
don't yet have some of the helper functions we want to in order to make this easier.

Fortunately the batching API is pretty simple. The idea with batching is that we're
gonna aggregate all the `author_id`s from each post, and then make one call to the user.

Let's first make a function to get a model by ids.

```elixir
defmodule MyApp.Schema.Helpers do
  def by_id(model, ids) do
    import Ecto.Query

    ids = ids |> Enum.uniq

    model
    |> where([m], m.id in ^ids)
    |> Repo.all
    |> Map.new(&{&1.id, &1})
  end
end
```

Now we can use this function to batch our author lookups:

```elixir
object :post do
  @desc "Author of the post"
  field :author, :user do
    resolve fn post, _, _ ->
      batch({MyApp.Schema.Helpers, :by_id, User}, post.author_id, fn batch_results ->
        {:ok, Map.get(batch_results, post.author_id)}
      end)
    end
  end
end
```

Now we make just two calls to the database. The first call loads all of the posts.
Then as Absinthe walks through each post and tries to get the author, it's instead
told to aggregate its information.

That aggregate information is passed on to our `by_id/2` function from earlier.
It grabs ALL the users in just one database call, and creates a map of user ids
to users.

Absinthe then does a second pass and calls the `batch_results` function with that
map, letting us retrieve the individual author for each post.

Not only is this a very efficient way to query the data, it's also 100% dynamic.
If a query document asks for authors, they're loaded efficiently. If it does not,
they aren't loaded at all.

## The Future

The `batch` API above is a bit verbose. This verbosity happens because it's very
generic, so you gotta give it the individual bits and pieces. However for Ecto
associations specifically, you can easily see how the code we have above could be
made more succinct by using information we already have on our Ecto schemas.

Thus what we hope to have soon in Absinthe.Ecto (doesn't exist yet) are functions
that let you do something like:

```elixir
object :post do
  field :name, :string
  field :author, :user, resolve: belongs_to(User, :author)
  field :comments, list_of(:comment), resolve: has_many(Comment)
end
```

This `belongs_to` function would derive the right batching approach based on the
Ecto association. These functions are mere conveniences. Everything they would do
functionally is available to you today!
