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

This is going to get tedious and error prone very quickly what if we could support a query that supports associations like

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

This way associations are all handled in the context [business logic aware](https://github.com/absinthe-graphql/absinthe/issues/443#issuecomment-405929499) conditions, to support this is actually surprisingly simple


Since we had already setup users to load associated posts we can change that to use dataloader to illustrate how much simpler this gets 


Let's start by adding `dataloader` as a dependency

In `mix.exs`

```elixir
defp deps do
  [
    {:dataloader, "~> 1.0.4"}
    << other deps >>
  ]
```

Then we need to set up dataloader in our context to enable use to load associations using rules

In `lib/blog/content.ex`:

```elixir
  def data(), do: Dataloader.Ecto.new(Repo, query: &query/2)
  
  def query(queryable, params) do
    
    queryable
  end 
```

This sets up  a loader that can use pattern matching to load different rules for different queryables, also note this function is passed in the context as the second parameter and that can be used for further filtering


Then lets add a configuration to our schema so that we can enable Absinthe to use Dataloader 


In `lib/blog_web/schema.ex`:


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

  << rest of the file>>
```


The loader is all set up  lets now modify the resolver to use Dataloader

In `lib/blog_web/schema/account_types.ex`

modify the user object to look as follows

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


And that's it! You are now loading associations using [Dataloader](https://github.com/absinthe-graphql/dataloader)

Check out the [docs](https://hexdocs.pm/dataloader/) for more non trivial ways of using Dataloader 


