# Deprecation

Use the `deprecate` option when defining any field, argument, or enum value.

- Provide a binary value to give a deprecation reason
- Provide `true` to just mark it as deprecated

An example:

```elixir
query do
  field :item, :item do
    arg :id, non_null(:id)
    arg :oldId, non_null(:string), deprecate: "It's old."
    resolve fn %{id: item_id}, _ ->
      {:ok, @items[item_id]}
    end
  end
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

<p class="warning">
At the current time, Absinthe reports any deprecated argument or
deprecated input object field used in the <code>errors</code> entry of the
result. Non-null constraints are ignored when validating deprecated arguments and
input object fields.
</p>
