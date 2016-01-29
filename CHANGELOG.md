# Changelog

## v0.5.0

The following changes are required if you're upgrading from the previous version:

### Resolution Functions

The second argument passed to resolution functions has changed from
`Absinthe.Execution.t` to a flatter, simpler data structure,
`Absinthe.Execution.Field.t`. This struct will be a more carefully curated
selection of metadata and match more closely to values in the JS
reference implementation.

See the typedoc for information about `Absinthe.Execution.Field.t`, and change
any advanced resolvers to use this new struct. The most likely change will be
the use of `source` instead of `resolution.target`.

## v0.4.0

The following changes are required if you're upgrading from the previous version:

### Enums

Instead of providing a map to `:values`, use the `values/1` convenience function from `Absinthe.Type.Definitions`:

Before:

```elixir
%Type.Enum{
  values: %{
    "foo" => :f,
    "bar" => :b
  }
}
```

Now:

```elixir
%Type.Enum{
  values: values(
    foo: [value: :f],
    bar: [value: :b]
  )
}
```

This allows us to support `:description` and deprecated values as used elsewhere. See `Absinthe.Type.Enum` for more information.

## v0.3.0

The following changes are required if you're upgrading from the previous version:

### Adapters

If using `Absinthe.Adapters.Passthrough`, you must manually configure it,
[as explained in the README](./README.md#adapters), now that the default has
changed to `Absinthe.Adapters.LanguageConventions`.
