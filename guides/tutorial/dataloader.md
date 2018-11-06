# Dataloader

Maybe you like good performance, or you realized that you are filling your objects with fields that need resolvers like 

```elixir
@desc "A user of the blog"
  object :user do
    field :id, :id
    field :name, :string
    field :contacts, list_of(:contact)
    field :posts, list_of(:post) do
      arg :date, :date
      resolve &Resolvers.Content.list_posts/3
    end
  end
```

This is going to get tedious and error-prone very quickly what if we could support a query that supports associations like

```elixir 
@desc "A user of the blog"
  object :user do
    field :id, :id
    field :name, :string
    field :contacts, list_of(:contact)
    field :posts, list_of(:post) do
       arg :date, :date
       resolve: dataloader(Content))
   end 
  end
```

This way associations are all handled in the context [business logic aware](https://github.com/absinthe-graphql/absinthe/issues/443#issuecomment-405929499) conditions, to support this is actually surprisingly simple.

Since we had already setup users to load associated posts we can change that to use dataloader to illustrate how much simpler this gets.

Let's start by adding `dataloader` as a dependency in `mix.exs`:

```elixir
defp deps do
  [
    {:dataloader, "~> 1.0.4"}
    << other deps >>
  ]
```

Next, we need to set up dataloader in our context which allows us to load associations using rules:

In `lib/blog/content.ex`:

```elixir
  def data(), do: Dataloader.Ecto.new(Repo, query: &query/2)
  
  def query(queryable, params) do
    
    queryable
  end 
```

This sets up a loader that can use pattern matching to load different rules for different queryables, also note this function is passed in the context as the second parameter and that can be used for further filtering.

Then let's add a configuration to our schema (in `lib/blog_web/schema.ex`) so that we can allow Absinthe to use Dataloader:

```elixir
defmodule BlogWeb.Schema do
  use Absinthe.Schema
  
  def context(ctx) do
     loader =
       Dataloader.new()
       |> Dataloader.add_source(Content, Content.data())

    Map.put(ctx, :loader, loader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader | Absinthe.Plugin.defaults()]
  end

  # << rest of the file>>
```

The loader is all set up, now let's modify the resolver to use Dataloader. In `lib/blog_web/schema/account_types.ex` modify the user object to look as follows:

```elixir
@desc "A user of the blog"
  object :user do
    field :id, :id
    field :name, :string
    field :contacts, list_of(:contact)
    field :posts, list_of(:post) do
       arg :date, :date
       resolve: dataloader(Content))
   end 
  end
```

That's it! You are now loading associations using [Dataloader](https://github.com/absinthe-graphql/dataloader)

## More Examples 
While the above examples are simple and straightforward we can use other strategies with loading associations consider the following:

```elixir
object :user do
  field :posts, list_of(:post), resolve: fn user, args, %{context: %{loader: loader}} ->
    loader
    |> Dataloader.load(Blog, :posts, user)
    |> on_load(fn loader ->
      {:ok, Dataloader.get(loader, Blog, :posts, user)}
    end)
  end
```

In this example, we are passing some args go the query in the context where our source lives. For example, this function now receives `args` as `params` meaning we can do now do fun stuff like apply rules to our queries like the following:

```elixir
def query(query, %{has_admin_rights: true}), do: query

def query(query, _), do: from(a in query, select_merge: %{street_number: nil})
```

This example is from the awesome [EmCasa Application](https://github.com/emcasa/backend/blob/master/apps/re/lib/addresses/addresses.ex) :) you can see how the [author](https://github.com/rhnonose) is only loading street numbers if a user has admin rights and the same used in a [resolver](https://github.com/emcasa/backend/blob/9a0f86c11499be6e1a07d0b0acf1785521eedf7f/apps/re_web/lib/graphql/resolvers/addresses.ex#L11).

Check out the [docs](https://hexdocs.pm/dataloader/) for more non-trivial ways of using Dataloader.
