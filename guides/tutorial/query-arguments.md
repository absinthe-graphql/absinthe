# Query Arguments

Our GraphQL API would be pretty boring (and useless) if clients
couldn't retrieve filtered data.

Let's assume that our API needs to add the ability to look-up users by
their ID and get the posts that they've authored. Here's what a basic query to do that
might look like:

```graphql
{
  user(id: "1") {
    name
    posts {
      id
      title
    }
  }
}
```

The query includes a field argument, `id`, contained within the
parentheses after the `user` field name. To make this all work, we need to modify
our schema a bit.

## Defining Arguments

First, let's create a `:user` type and define its relationship to
`:post` while we're at it. We'll create a new module for the
account-related types and put it there; in
`blog_web/schema/account_types.ex`:

```elixir
defmodule BlogWeb.Schema.AccountTypes do
  use Absinthe.Schema.Notation

  @desc "A user of the blog"
  object :user do
    field :id, :id
    field :name, :string
    field :email, :string
    field :posts, list_of(:post)
  end

end
```

The `:posts` field points to a list of `:post` results. (This matches
up with what we have on the Ecto side, where `Blog.Accounts.User`
defines a `has_many` association with `Blog.Content.Post`.)

We've already defined the `:post` type, but let's go ahead and add an
`:author` field that points back to our `:user` type. In
`blog_web/schema/content_types.ex`:

``` elixir
object :post do

  # post fields we defined earlier...

  field :author, :user

end
```

Now let's add the `:user` field to our query root object in our
schema, defining a mandatory `:id` argument and using the
`Resolvers.Accounts.find_user/3` resolver function. We also need to
make sure we import the types from `BlogWeb.Schema.AccountTypes` so
that `:user` is available.

In `blog_web/schema.ex`:

```elixir
defmodule BlogWeb.Schema do
  use Absinthe.Schema

  import_types Absinthe.Type.Custom

  # Add this `import_types`:
  import_types BlogWeb.Schema.AccountTypes

  import_types BlogWeb.Schema.ContentTypes

  alias BlogWeb.Resolvers

  query do

    @desc "Get all posts"
    field :posts, list_of(:post) do
      resolve &Resolvers.Content.list_posts/3
    end

    # Add this field:
    @desc "Get a user of the blog"
    field :user, :user do
      arg :id, non_null(:id)
      resolve &Resolvers.Accounts.find_user/3
    end

  end

end
```

Now lets use the argument in our resolver. In `blog_web/resolvers/accounts.ex`:

```elixir
defmodule BlogWeb.Resolvers.Accounts do

  def find_user(_parent, %{id: id}, _resolution) do
    case Blog.Accounts.find_user(id) do
      nil ->
        {:error, "User ID #{id} not found"}
      user ->
        {:ok, user}
    end
  end

end
```

Our schema marks the `:id` argument as `non_null`, so we can be
certain we will receive it. If `:id` is left out of the query,
Absinthe will return an informative error to the user, and the resolve
function will not be called.

> If you have experience writing Phoenix controller actions, you might
> wonder why we can match incoming arguments with atoms instead of
> having to use strings.
>
> The answer is simple: you've defined the arguments in the schema
> using atom identifiers, so Absinthe knows what arguments will be
> used ahead of time, and will coerce as appropriate---culling any
> extraneous arguments given to a query. This means that all arguments
> can be supplied to the resolve functions with atom keys.

Finally you'll see that we can handle the possibility that the query,
while valid from GraphQL's perspective, may still ask for a user that
does not exist. We've decided to return an error in that case.

> There's a valid argument for just returning `{:ok, nil}` when a
> record can't be found. Whether the absence of data constitutes an
> error is a decision you get to make.

## Arguments and Non-Root Fields

Let's assume we want to query all posts from a user published within a
given time range. First, let's add a new field to our `:post` object
type, `:published_at`.

The GraphQL specification doesn't define any official date or time
types, but it does support custom scalar types (you can read more
about them in the [related guide](custom-scalars.md), and
Absinthe ships with several built-in scalar types. We'll use
`:naive_datetime` (which doesn't include timezone information) here.

Edit `blog_web/schema/content_types.ex`:

```elixir
defmodule BlogWeb.Schema.ContentTypes do
  use Absinthe.Schema.Notation

  @desc "A blog post"
  object :post do
    field :id, :id
    field :title, :string
    field :body, :string
    field :author, :user
    # Add this:
    field :published_at, :naive_datetime
  end
end
```

To make the `:naive_datetime` type available, add an `import_types` line to
your `blog_web/schema.ex`:

``` elixir
import_types Absinthe.Type.Custom
```

> For more information about how types are imported,
> read [the guide on the topic](importing-types.md).
>
> For now, just remember that `import_types` should _only_ be
> used in top-level schema module. (Think of it like a manifest.)

Here's the query we'd like to be able to use, getting the posts for a user
on a given date:

```graphql
{
  user(id: "1") {
    name
    posts(date: "2017-01-01") {
      title
      body
      publishedAt
    }
  }
}
```

To use the passed date, we need to update our `:user` object type and
make some changes to its `:posts` field; it needs to support a `:date`
argument and use a custom resolver. In `blog_web/schema/account_types.ex`:

```elixir
defmodule BlogWeb.Schema.AccountTypes do
  use Absinthe.Schema.Notation

  alias BlogWeb.Resolvers

  object :user do
    field :id, :id
    field :name, :string
    field :email, :string
    # Add the block here:
    field :posts, list_of(:post) do
      arg :date, :date
      resolve &Resolvers.Content.list_posts/3
    end
  end

end
```

For the resolver, we've added another function head to
`Resolvers.Content.list_posts/3`. This illustrates how you can use the
first argument to a resolver to match the parent object of a field. In
this case, that parent object would be a `Blog.Accounts.User` Ecto
schema:

``` elixir
# Add this:
def list_posts(%Blog.Accounts.User{} = author, args, _resolution) do
  {:ok, Blog.Content.list_posts(author, args)}
end
# Before this:
def list_posts(_parent, _args, _resolution) do
  {:ok, Blog.Content.list_posts()}
end
```

Here we pass on the user and arguments to the domain logic function,
`Blog.Content.list_posts/3`, which will find the posts for the user
and date (if it's provided; the `:date` argument is optional). The
resolver, just as when it's used for the top level query `:posts`,
returns the posts in an `:ok` tuple.

> Check out the full implementation of logic for
> `Blog.Content.list_posts/3`--and some simple seed data--in
> the
> [absinthe_tutorial](https://github.com/absinthe-graphql/absinthe_tutorial) repository.

If you've done everything correctly (and have some data handy), if you
start up your server with `mix phx.server` and head over
to <http://localhost:4000/api/graphiql>, you should be able to play
with the query.

It should look something like this:

<img style="box-shadow: 0 0 6px #ccc;" src="/guides/assets/tutorial/graphiql_user_posts.png" alt=""/>

## Next Step

Next up, we look at how to modify our data using [mutations](mutations.md).
