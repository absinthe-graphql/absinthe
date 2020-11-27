# Importing Types

It doesn't take long for a schema module to become crowded with types,
resolvers, and other customizations.

A good first step in cleaning up your schema is extracting your types,
organizing them into other modules, and then using `Absinthe.Schema.Notation.import_types/1`
to make them available to your schema.

## Example

Let's say you have a schema that looks something like this:

``` elixir
defmodule MyAppWeb.Schema do
  use Absinthe.Schema

  object :user do
    field :name, :string
  end

  # Rest of the schema...

end
```

You could extract your `:user` type into a module, `MyAppWeb.Schema.AccountTypes`:

``` elixir
defmodule MyAppWeb.Schema.AccountTypes do
  use Absinthe.Schema.Notation

  object :user do
    field :name, :string
  end
end
```

> Note that, unlike your schema module, _type modules_ should use
> `Absinthe.Schema.Notation`, *not* `Absinthe.Schema`.

Now, you need to make sure you use `import_types` to tell your schema
where to find additional types:

``` elixir
defmodule MyAppWeb.Schema do
  use Absinthe.Schema

  import_types MyAppWeb.Schema.AccountTypes

  # Rest of the schema...
end
```

> Important: You should _only_ use `import_types` from your schema
> module; think of it like a manifest.

Now, your schema will be able to resolve any references to your `:user` type
during compilation.

## What about root types?

Root types (which are defined using the `query`, `mutation`, and
`subscription` macros), can only be defined on the schema module---you
can't extract them, but you can use the `import_fields` mechanism to
extract their contents.

Here's an example:

``` elixir
query do
  import_fields :account_queries
end
```

This will look for a matching object type `:account_queries`, and pull
its fields into the root query type.

For more information, see the [guide](importing-fields.md).
