# Mutations

A blog is no good without new content. We want to support a mutation
to create a blog post:

```graphql
mutation CreatePost {
  createPost(title: "Second", body: "We're off to a great start!") {
    id
  }
}
```

Now we just need to define a `mutation` portion of our schema and
a `:create_post` field:

In `blog_web/schema.ex`:

```elixir
mutation do

  @desc "Create a post"
  field :create_post, type: :post do
    arg :title, non_null(:string)
    arg :body, non_null(:string)
    arg :published_at, :naive_datetime

    resolve &Resolvers.Content.create_post/3
  end

end
```

The resolver in this case is responsible for making any changes and
returning an `{:ok, post}` tuple matching the `:post` type we defined
earlier:

In our `blog_web/resolvers/content.ex` module, we'll add the
`create_post/3` resolver function:

```elixir
def create_post(_parent, args, %{context: %{current_user: user}}) do
  Blog.Content.create_post(user, args)
end
def create_post(_parent, _args, _resolution) do
  {:error, "Access denied"}
end
```

> Obviously things can go wrong in a mutation. To learn more about the
> types of error results that Absinthe supports, read [the guide](errors.md).

## Authorization

This resolver adds a new concept: authorization. The resolution struct
(that is, an `Absinthe.Resolution`)
passed to the resolver as the third argument carries along with it the
Absinthe context, a data structure that serves as the integration
point with external mechanisms---like a Plug that authenticates the
current user. You can learn more about how the context can be used in
the [Context and Authentication](context-and-authentication.md)
guide.

Going back to the resolver code:

- If the match for a current user is successful, the underlying
  `Blog.Content.create_post/2` function is invoked. It will return a
  tuple suitable for return. (To read the Ecto-related nitty gritty,
  check out the [absinthe_tutorial](https://github.com/absinthe-graphql/absinthe_tutorial)
  repository.)
- If the match for a current user isn't successful, the fall-through
  match will return an error indicating that a post can't be created.

## Next Step

Now let's take a look at [more complex arguments](complex-arguments.md)
