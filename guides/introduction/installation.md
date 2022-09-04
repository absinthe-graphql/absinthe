# Installation

To install Absinthe, just add an entry to your `mix.exs`:

``` elixir
def deps do
  [
    # ...
    {:absinthe, "~> 1.5"}
  ]
end
```

(Check [Hex](https://hex.pm/packages/absinthe) to make sure you're using an up-to-date version number.)

## Overriding Dependencies

Because the Absinthe project is made up of a large number of related packages to support integrations with other tools, sometimes you may want to update only part of your absinthe-related dependencies.

Don't forget you can use the [:override](https://hexdocs.pm/mix/Mix.Tasks.Deps.html#module-dependency-definition-options) option for your Mix dependencies if you'd like to ensure a specific package is at a specific version number. For example, If you wanted to try a new version of Absinthe without updating something that depends on it (which is locked to an older version):

``` elixir
def deps do
  [
    # ...
    {:absinthe, "~> 1.5", override: true}
  ]
end
```

## Plug, Phoenix, and GraphiQL

Most people use Absinthe to support an HTTP API.

You'll want to read the [Plug and Phoenix](plug-phoenix.md) for specific installation and configuration options, including how you can run the handy, included GraphiQL tool directly from your application.
