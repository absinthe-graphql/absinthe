# Our First Query

The first thing our viewers want is a list of our blog posts, so
that's what we're going to give them. Here's the query we want to
support:

```graphql
{
  posts {
    title
    body
  }
}
```

To do this we're going to need a schema. Let's create some basic types
for our schema, starting with a `:post`. GraphQL has several fundamental
types on top of which all of our types will be
built. The `Absinthe.Type.Object` type is the right one
to use when representing a set of key value pairs.

Since our `Post` Ecto schema lives in the `Blog.Content` Phoenix
context, we'll define its GraphQL counterpart type, `:post`, in a
matching `BlogWeb.Schema.ContentTypes` module:

In `blog_web/schema/content_types.ex`:

```elixir
defmodule BlogWeb.Schema.ContentTypes do
  use Absinthe.Schema.Notation

  object :post do
    field :id, :id
    field :title, :string
    field :body, :string
  end
end
```

> The GraphQL specification requires that type names be unique, TitleCased words.
> Absinthe does this automatically for us, extrapolating from our type identifier
> (in this case `:post` gives us `"Post"`. If really needed, we could provide a
> custom type name as a `:name` option to the `object` macro.

If you're curious what the type `:id` is used by the `:id` field, see
the [GraphQL spec](https://facebook.github.io/graphql/#sec-ID). It's
an opaque value, and in our case is just the regular Ecto id, but
serialized as a string.

With our type completed we can now write a basic schema that will let
us query a set of posts.

In `blog_web/schema.ex`:

```elixir
defmodule BlogWeb.Schema do
  use Absinthe.Schema
  import_types BlogWeb.Schema.ContentTypes

  alias BlogWeb.Resolvers

  query do

    @desc "Get all posts"
    field :posts, list_of(:post) do
      resolve &Resolvers.Content.list_posts/3
    end

  end

end
```

> For more information on the macros available to build a schema, see
> their definitions in `Absinthe.Schema` and
> `Absinthe.Schema.Notation`.

This uses a resolver module we've created (again, to match the Phoenix context naming)
at `blog_web/resolvers/content.ex`:

```elixir
defmodule BlogWeb.Resolvers.Content do

  def list_posts(_parent, _args, _resolution) do
    {:ok, Blog.Content.list_posts()}
  end

end
```

Queries are defined as fields inside the GraphQL object returned by
our `query` function. We created a posts query that has a type
`list_of(:post)` and is resolved by our
`BlogWeb.Resolvers.Content.list_posts/3` function. Later we'll talk
more about the resolver function parameters; for now just remember
that resolver functions can take two forms:

- A function with an arity of 3 (taking a parent, arguments, and resolution struct)
- An alternate, short form with an arity of 2 (omitting the first parameter, the parent)

The job of the resolver function is to return the data for the
requested field. Our resolver calls out to the `Blog.Content` module,
which is where all the domain logic for posts lives, invoking its
`list_posts/0` function, then returns the posts in an `:ok` tuple.

> Resolvers can return a wide variety of results, to include errors and configuration
> for [advanced plugins](middleware-and-plugins.md) that further process the data.
>
> If you're asking yourself what the implementation of the domain logic looks like, and exactly how
> the related Ecto schemas are built, read through the code in the [absinthe_tutorial](http://github.com/absinthe-graphql/absinthe_tutorial)
> repository. The tutorial content here is intentionally focused on the Absinthe-specific code.

Now that we have the functional pieces in place, let's configure our
Phoenix router to wire this into HTTP:

In `blog_web/router.ex`:

```elixir
defmodule BlogWeb.Router do
  use BlogWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api" do
    pipe_through :api

    forward "/graphiql", Absinthe.Plug.GraphiQL,
      schema: BlogWeb.Schema

    forward "/", Absinthe.Plug,
      schema: BlogWeb.Schema

  end

end
```

In addition to our API, we've wired in a handy GraphiQL user interface to play with it. Absinthe integrates both the classic [GraphiQL](https://github.com/graphql/graphiql) and  more advanced [GraphiQL Workspace](https://github.com/OlegIlyenko/graphiql-workspace) interfaces as part of the [absinthe_plug](https://hex.pm/packages/absinthe_plug) package.

Now let's check to make sure everything is working. Start the server:

``` shell
$ mix phx.server
```

Absinthe does a number of sanity checks during compilation, so if you misspell a type or make another schema-related gaffe, you'll be notified.

Once it's up-and-running, take a look at [http://localhost:4000/api/graphiql](http://localhost:4000/api/graphiql):

<img style="box-shadow: 0 0 6px #ccc;" src="/guides/assets/tutorial/graphiql_blank.png" alt=""/>

Make sure that the `URL` is pointing to the correct place and press the play button. If everything goes according to plan, you should see something like this:

<img style="box-shadow: 0 0 6px #ccc;" src="/guides/assets/tutorial/graphiql.png" alt=""/>

## Next Step

Now let's look at how we can [add arguments to our queries](query-arguments.md).
