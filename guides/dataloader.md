# Dataloader

Dataloader provides an easy way efficiently load data in batches.
It's inspired by https://github.com/facebook/dataloader

## Installation

```elixir
def deps do
  [
    {:dataloader, "~> 1.0.0"}
  ]
end
```

## Usage

The core concept of dataloader is a data source which is just a struct
that encodes a way of retrieving data. More info in the [Sources](#sources) section.

### Schema

Absinthe provides some dataloader helpers out of the box that you can import into your schema

```elixir
import Absinthe.Resolution.Helpers, only: [dataloader: 1]
```

This is needed to use the various `dataloader` helpers to resolve a field:

```elixir
field(:posts, list_of(:post), resolve: dataloader(Blog))
```

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
alias MyApp.{Blog, Foo}

def context(ctx) do
  loader =
    Dataloader.new
    |> Dataloader.add_source(Blog, Blog.data())
    |> Dataloader.add_source(Foo, Foo.data()) # Foo source could be a Redis source

  Map.put(ctx, :loader, loader)
end

def plugins do
  [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
end
```

The `context/1` function is a callback specified by the `Absinthe.Schema` behaviour that gives
the schema itself an opportunity to set some values in the context that it may need in order to run.

The `plugins/0` function has been around for a while, and specifies what plugins the schema needs to resolve.
See [the documentation](`c:Absinthe.Schema.plugins/0`) for more.

#### Unpacking Dataloader

The `data/0` function creates an Ecto data source, to which you pass your repo and a query function. This query function
is called every time you want to load something, and provides an opportunity to apply arguments or
set defaults. So for example if you always want to only load non-deleted posts you can do:

```elixir
def query(Post, _), do: from p in Post, where: is_nil(p.deleted_at)

def query(queryable, _), do: queryable
```

Now any time you're loading posts, you'll just get posts that haven't been
deleted.

We can also use the context to ensure access conditions, so we can only show deleted posts for admins:

```elixir
def query(Post, %{has_admin_rights: true}), do: Post

def query(Post, _), do: from p in Post, where: is_nil(p.deleted_at)

def query(queryable, _), do: queryable
```

Helpfully, those rules are defined within your context, helping ensure
that it has the final say about data access.

### Sources

Dataloader ships with two different built in sources:

* `Dataloader.Ecto` - for easily pulling out data with ecto
* `Dataloader.KV` - a simple KV key value source.

#### KV

Here is a simple example of a loader using the `KV` source in combination with absinthe:

```elixir
defmodule MyProject.Loaders.Nhl do
  @teams [%{
    id: 1,
    name: "New Jersey Devils",
    abbreviation: "NJD"
  },
  %{
    id: 2,
    name: "New York Islanders",
    abbreviation: "NYI"
  }
  # etc.
  ]

  def data() do
    Dataloader.KV.new(&fetch/2)
  end

  def fetch(:teams, [%{}]) do
    %{
      %{} => @teams
    }
  end

  def fetch(:team, args) do
   # must return a map keyed by the args
   # args is a list of the args used to resolve your field
   # for example, if you have arg(:foo, non_null(:string))
   # args will look like: [%{foo: "value of foo here")}]

    args
    |> Enum.reduce(%{}, fn(%{id: id} = arg, result) ->
      Map.put(result, arg, find_team(id))
    end)
  end

  def fetch(_batch, args) do
    args |> Enum.reduce(%{}, fn(arg, accum) -> Map.put(accum, arg, nil) end)
  end

  defp find_team(id) do
    @teams |> Enum.find(fn(t) -> t |> Map.get(:id) == id end)
  end
end
```

`Dataloader.KV` requires a load function that accepts a batch and args. It must return a map of values keyed by the args.
This is the purpose of the `fetch/2` function. The `dataloader/1` helper we imported above uses the field name as the batch, and a map where the argument name is the key. For example: `fetch(:team, [%{ id: 1 }])`

Pattern matching can be used to fetch differently depending on the batch. For example, when the :teams batch is requested, the args will actually be an empty map (i.e. `%{}`).

If you’re interested in more generic use of Dataloader, see the [dataloader project source](https://github.com/absinthe-graphql/dataloader).