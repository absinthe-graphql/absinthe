# Changelog

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
