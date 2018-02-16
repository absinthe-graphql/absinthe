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
field(:teams, list_of(:team), resolve: dataloader(Nhl))
```

It also provides a plugin you need to add to help with resolution:

```elixir
def plugins do
  [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
end
```

Finally you need to make sure your loader is in your context:

```elixir
def context(ctx) do
  loader =
    Dataloader.new()
    |> Dataloader.add_source(Nhl, Nhl.data())

  Map.put(ctx, :loader, loader)
end
```

Putting all that together looks like this:

```elixir
defmodule MyProject.Schema do
  use Absinthe.Schema
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias MyProject.Loaders.Nhl

  def context(ctx) do
    loader =
      Dataloader.new()
      |> Dataloader.add_source(Nhl, Nhl.data())

    Map.put(ctx, :loader, loader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end

  object :team do
    field(:id, non_null(:id))
    field(:name, non_null(:string))
    field(:city, non_null(:string))
  end

  query do
    field(:teams, list_of(:team), resolve: dataloader(Nhl))
    field :team, :team do
      arg(:id, non_null(:id))
      resolve(dataloader(Nhl))
    end
  end
end
```

### Sources

Dataloader ships with two different built in sources:

* Ecto - for easily pulling out data with ecto
* KV - a simple KV key value source.

#### KV

Here is a simple example of a loader using the `KV` source in combination with absinthe:

```elixir
defmodule MyProject.Loaders.Nhl do
  def data() do
    Dataloader.KV.new(&fetch/2)
  end

  def fetch(batch, ids) do
    # must return a map keyed by the ids
  end
end
```
