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

In `web/schema/types`:

```elixir
@desc "A user of the blog"
object :user do
  field :id, :id
  field :name, :string
  field :email, :string
  field :posts, list_of(:post)
end

@desc "A blog post"
object :post do
  field :title, :string
  field :body, :string
  field :author, :user
end
```

In `web/schema.ex`:

```elixir
query do

  @desc "Get all blog posts"
  field :posts, list_of(:post) do
    resolve &Blog.PostResolver.all/2
  end

  @desc "Get a user of the blog"
  field :user, type: :user do
    arg :id, non_null(:id)
    resolve &Blog.UserResolver.find/2
  end

end
```

In GraphQL you define your arguments ahead of time just like your
return values. This powers a number of very helpful features. To see
them at work, let's look at our resolver.

In `web/resolvers/user_resolver.ex`:

```elixir
defmodule Blog.UserResolver do
  def find(%{id: id}, _info) do
    case Blog.Repo.get(User, id) do
      nil  -> {:error, "User id #{id} not found"}
      user -> {:ok, user}
    end
  end
end
```

Resolve functions are expected to return either `{:ok, item}` or
`{:error, binary | [binary, ...]}`.

The first argument to every resolve function contains the GraphQL
arguments of the query / mutation. Our schema marks the `:id` argument
as `non_null`, so we can be certain we will receive it and just
pattern match directly. If `:id` is left out of the query, Absinthe
will return an informative error to the user, and the resolve function
will not be called.

Note also that the `:id` parameter is an atom, and not a binary like
ordinary phoenix parameters. Absinthe knows what arguments will be
used ahead of time, will coerce as appropriate -- and will cull any
extraneous arguments given to a query. This means that all arguments
can be supplied to the resolve functions with atom keys.

Finally you'll see that we need to handle the possibility that the
query, while valid from GraphQL's perspective, may still ask for a
user that does not exist.

## Arguments for Non-Root Fields

Let's assume, we want to query all posts from the user on a given
date.  First, let's add a `date` field to our `Post` object. We can
use the built-in `date` scalar from Absinthe.

```elixir
# Import types from Absinthe
import_types Absinthe.Type.Custom

@desc "A blog post"
object :post do
  field :title, :string
  field :body, :string
  field :author, :user
  field :date, :date
end
```

Our ideal GraphQL query to get all posts from a user on a given date
could look like this:

```graphql
{
  user(id: "1") {
    name
    email
    posts(date: "2017-01-01") {
      title
      body
      date
    }
  }
}
```

To use the passed date in our resolver, we need to add this argument
to our user type definition.

```elixir
@desc "A user of the blog"
object :user do
  field :id, :id
  field :name, :string
  field :email, :string
  field :posts, list_of(:post) do
    arg :date, :date
    resolve &Blog.PostResolver.all/3 # We now use resolve with a 3-arity function
  end
end
```

As you see, we now use `resolve/3` where the first argument is the
parent (our user) and the second argument are the field arguments (our
date). We now can return all posts from the given user on a given date
in our `PostResolver`.

In `web/resolvers/post_resolver.ex`:

```elixir
defmodule Blog.PostResolver do
  def all(%{id: id}, args, _info) do
    query = Post
    |> where(author_id: ^id)

    query = case args[:date] do
      nil -> query
      date -> query |> where(date: ^date)
    end

    {:ok, Blog.Repo.all(query)}
  end
end
```

Our `date` argument is optional so we can query all posts from a user
or just the posts on the given date.  This is just an example, how you
can build such a query with optional `where` clauses.
