# Schema Deprecation

Use the `deprecate` option when defining any field or enum value.

- Provide a binary value to give a deprecation reason
- Provide `true` to just mark it as deprecated

An example:

```elixir
query do
  field :old_item, :item, deprecate: true
  field :another_old_item, :item, deprecate: "still too old"
end
```

You can also use the `deprecate` as a macro inside a block, for instance:

```elixir
field :age, :integer do
  deprecate
  arg :user_id, non_null(:id)
end
```

With a reason:

```elixir
field :ssn, :string do
  deprecate "Privacy concerns"
end
```

> Warning: Deprecated fields and enum values are not reported by default during [introspection](introspection.md).
