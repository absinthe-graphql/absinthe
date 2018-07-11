# Document Adapters

Absinthe supports an adapter mechanism that allows developers to define their
schema using one code convention (eg, `snake_cased` fields and arguments), but
accept query documents and return results (including names in errors) in
another (eg, `camelCase`). This is useful in allowing both client and server to
use conventions most natural to them.

Absinthe ships with two adapters:

* `Absinthe.Adapter.LanguageConventions`, which expects schemas to be defined
  in `snake_case` (the standard Elixir convention), translating to/from `camelCase`
  for incoming query documents and outgoing results. This is the default as of v0.3,
  and it is _highly_ recommended that it's the adapter you use, as introspection
  currently makes certain assumptions about how to return results.
* `Absinthe.Adapter.Underscore`, which is similar to the `LanguageConventions`
  adapter but converts all incoming identifiers to underscores and does not
  modify outgoing identifiers (since those are already expected to be
  underscores). Unlike `Absinthe.Adapter.Passthrough` this does not break
  introspection.
* `Absinthe.Adapter.Passthrough`, which is a no-op adapter and makes no
  modifications.

To set the adapter, you can set an application configuration value:

```elixir
config :absinthe,
  adapter: Absinthe.Adapter.TheAdapterName
```

Or, you can provide it as an option to `Absinthe.run/3`:

```elixir
Absinthe.run(query, MyAppWeb.Schema,
             adapter: Absinthe.Adapter.TheAdapterName)
```

Notably, this means you're able to switch adapters on case-by-case basis.
In a Phoenix application, this means you could even support using different
adapters for different clients.

A custom adapter module must merely implement the `Absinthe.Adapter` protocol,
in many cases with `use Absinthe.Adapter` and only overriding the desired
functions.

Note that types that are defined external to your application (including
the introspection types) may not be compatible if you're using a different
adapter.
