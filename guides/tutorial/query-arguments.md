# Query Arguments

Our blog needs users, and the ability to look up users by id. Here's
the query we want to support:

```graphql
{
  user(id: "1") {
    name
    email
  }
}
```

This query includes arguments, which are the key value pairs contained
within the parenthesis. To support this, we'll first create a user
type, and then create a query in our schema that takes an id argument.

We'll add another module for the account-related types; in `blog_web/schema/account_types`:

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

The `:posts` field points to a list of `:post` results.

We defined the `:post` type earlier. Let's add an `:author` field that
points back to our `:user` type:

``` elixir
object :post do

  # post fields we defined earlier...

  field :author, :user

end
```

Now let's add the `:user` field to our query root object in our schema, defining a mandatory argument and using the `Resolvers.Accounts.find_user/3` resolver function. We also need to make sure we import the types from `BlogWeb.Schema.AccountTypes` so `:user` is available.

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

In GraphQL you define your arguments ahead of time---just like your
return values. This powers a number of very helpful features. To see
them at work, let's look at our resolver.

In `blog_web/resolvers/accounts.ex`:

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
certain we will receive it and just pattern match directly. If `:id`
is left out of the query, Absinthe will return an informative error to
the user, and the resolve function will not be called.

Note also that the `:id` parameter is an atom, and not a binary like
ordinary Phoenix parameters. Absinthe knows what arguments will be
used ahead of time, will coerce as appropriate---and will cull any
extraneous arguments given to a query. This means that all arguments
can be supplied to the resolve functions with atom keys.

Finally you'll see that we need to handle the possibility that the
query, while valid from GraphQL's perspective, may still ask for a
user that does not exist.

## Arguments for Non-Root Fields

Let's assume we want to query all posts from a user published within a
given time range. First, let's add a new field to our `:post` object
type, `:published_at`.

The GraphQL specification doesn't define any official date or time
types, but it does support custom scalar types (we'll talk about how
to define _those_ in the [next section](scalar-types.html), and
Absinthe ships with several built-in scalar types. We'll use
`:datetime` here.

Edit `blog_web/schema/content_types.ex`:

```elixir
defmodule BlogWeb.Schema.ContentTypes do
  # Add this:
  use Absinthe.Schema.Notation

  @desc "A blog post"
  object :post do
    field :id, :id
    field :title, :string
    field :body, :string
    field :author, :user
    # Add this:
    field :published_at, :datetime
  end
end
```

To make the `:datetime` type available, add an `import_types` line to your `blog_web/schema.ex`:

``` elixir
import_types Absinthe.Type.Custom
```

Here's the query we'd like to be able to use, getting the posts for a user
on a given date:

```graphql
{
  user(id: "1") {
    name
    email
    posts(date: "2017-01-01") {
      title
      body
      publishedAt
    }
  }
}
```

To use the passed date, we need to update our `:user` object type and
make some changes to its `:posts` field; it needs to support  a `:date`
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
`Resolvers.Content.find_posts/3`. This illustrates how you can use the
first argument to a resolver to match the parent object of a field. In
this case, that parent object would be a `Blog.Accounts.User` Ecto
schema:

``` elixir
# Add this:
def list_posts(%Blog.Content.User{} = author, args, _resolution) do
  {:ok, Blog.Content.list_posts(author, args)}
end
# Before this:
def list_posts(_parent, _args, _resolution) do
  {:ok, Blog.Content.list_posts()}
end
```

Here we pass on the user and arguments to the domain logic function,
`Blog.Content.list_posts/2`, which will find the posts for the user
and date (if it's provided; the `:date` argument is optional). The
resolver, just as when it's used for the top level query `:posts`,
returns the posts in an `:ok` tuple.

> Check out the full implementation of logic for `Blog.Content.list_posts/2` in the
> [absinthe_tutorial](https://github.com/absinthe-graphql/absinthe_tutorial) repository.

Next up, we look at how to change data from our API; [mutations](mutations.html).
