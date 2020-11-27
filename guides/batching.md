# Batching Resolution

## Avoiding N+1 Queries

In general, you want to make sure that when accessing Ecto associations that you
preload the data in the top level resolver functions to avoid N+1 queries.

Imagine this scenario: You have posts and users. A `Post` has an `author` field, which
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

One way to handle this issue is with Absinthe's support for
batching. The idea with batching is that we're gonna aggregate all the
`author_id`s from each post, and then make one call to the user.

Let's first make a function to get a model by ids:

```elixir
defmodule MyAppWeb.Schema.Helpers do
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
      batch({MyAppWeb.Schema.Helpers, :by_id, User}, post.author_id, fn batch_results ->
        {:ok, Map.get(batch_results, post.author_id)}
      end)
    end
  end

end
```

Now we make just two calls to the database. The first call loads all of the posts.
Then as Absinthe walks through each post and tries to get the author, it's instead
told to aggregate its information. That aggregate information is passed on to our `by_id/2` function from earlier.
It grabs ALL the users in just one database call, and creates a map of user ids
to users.

Absinthe then does a second pass and calls the `batch_results` function with that
map, letting us retrieve the individual author for each post.

Not only is this a very efficient way to query the data, it's also 100% dynamic.
If a query document asks for authors, they're loaded efficiently. If it does not,
they aren't loaded at all.

See the documentation for `Absinthe.Middleware.Batch` for more information.

`Absinthe.Middleware.Batch` achieves a lot and, with some helpers, was the
standard way to solve this problem for a long time. While batching still has a
place, it has a few limitations that have driven the development of Dataloader.
There are small scale annoyances like the limitation of only being able to batch
one thing at a time in a field, or the fact that the API can get very verbose.

There's also some larger scale issues however. Ecto has a fair number of quirks
that make it a difficult library to abstract access to. If you want the
concurrent test system to work, you need to add `self()` to all the batch keys
and do `Repo.all(caller: pid)` in every batch function so that it knows which
sandbox to use. It gets very easy for your GraphQL functions to become full of
direct database access, inevitably going around important data access rules you
may want to enforce in your contexts. Alternatively, your context functions can
end up with dozens of little functions that only exist to support batching items
by ID.

In time, people involved in larger projects have been able to build some
abstractions, helpers, and conventions around the `Absinthe.Middleware.Batch`
plugin that have done a good job of addressing these issues. That effort has been
extracted into the Dataloader project, which also draws inspiration from similar
projects in the GraphQL world.

We've made it easier and more flexible, however, with
Elixir's [dataloader](https://hex.pm/packages/dataloader) package.

### Dataloader

Let's jump straight in to getting Dataloader working, and then we'll expand on
what's actually happening behind the scenes.

Using Dataloader is as simple as doing:

```elixir
alias MyApp.Blog # Dataloader source, see below
import Absinthe.Resolution.Helpers, only: [dataloader: 1]

object :post do
  field :posts, list_of(:post), resolve: dataloader(Blog)

  @desc "Author of the post"
  field :author, :user do
    resolve dataloader(Blog)
  end
end
```

To make this work we need to setup a dataloader, add the `Blog` source to it, and
make sure our schema knows it needs to run the dataloader.

Latest install instructions found here: https://github.com/absinthe-graphql/dataloader

Let's start with a data source. Dataloader data sources are just structs that encode
a way of retrieving data in batches. In a Phoenix application you'll generally have one
source per context, so that each context can control how its data is loaded.

Here is a hypothetical `Blog` context and a dataloader ecto source:

```elixir
defmodule MyApp.Blog do
  def data() do
    Dataloader.Ecto.new(MyApp.Repo, query: &query/2)
  end

  def query(queryable, _params) do
    queryable
  end
end
```

When integrating Dataloader with GraphQL, we want to place it in our context so
that we can access it in our resolvers. In your schema module add:

```elixir
alias MyApp.{Blog}

def context(ctx) do
  loader =
    Dataloader.new
    |> Dataloader.add_source(Blog, Blog.data())

  Map.put(ctx, :loader, loader)
end

def plugins do
  [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
end
```

That's it! If you run a GraphQL query that hits that field, it will be loaded efficiently without N+1.

See the documentation for [Dataloader](dataloader.md) for more information.

### Deprecated in v1.4: Batching with Absinthe.Ecto

The batching helper functions present
in [absinthe_ecto](https://github.com/absinthe-graphql/absinthe_ecto)
provided some early support for making it easy to get data from Ecto. These batching features are considered *DEPRECATED* in favor of
Dataloader, described above. If you're on 1.4 or earlier absinthe version feel free to check the documentation about [`absinthe_ecto` basic usage](https://hexdocs.pm/absinthe_ecto/Absinthe.Ecto.html#module-basic-usage).
