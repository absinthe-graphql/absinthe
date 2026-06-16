# Directives

Directives provide a way to describe alternate runtime execution and type
validation behavior in a GraphQL document. They are written with a leading `@`
and can optionally take arguments, for example `@deprecated(reason: "...")`.

GraphQL defines two kinds of directives, and Absinthe ships with the built-in
directives described by the
[GraphQL specification (September 2025)](https://spec.graphql.org/September2025/#sec-Type-System.Directives):

- **Executable directives** are applied within a GraphQL *document* (a query,
  mutation, or subscription) to influence how it is executed---for example to
  conditionally include a field.
- **Type system directives** (also called *schema directives*) are applied
  within a *schema* to describe or alter the behavior of the types and fields it
  defines---for example to mark a field as deprecated.

You can also define your own directives. See `Absinthe.Schema.Notation.directive/1`
for executable directives and `Absinthe.Schema.Prototype` for type system
directives.

## Executable directives

Executable directives are applied to fields, fragment spreads, and inline
fragments in a document. Absinthe provides the two executable directives
required by the specification: `@skip` and `@include`. Both take a single
non-null boolean `if` argument and are typically driven by a variable.

### `@include`

Includes the annotated field or fragment only when the `if` argument is `true`.

```graphql
query GetItem($withName: Boolean!) {
  item(id: "foo") {
    id
    name @include(if: $withName)
  }
}
```

### `@skip`

Skips (omits) the annotated field or fragment when the `if` argument is `true`.
When both `@skip` and `@include` are present, `@skip` takes precedence.

```graphql
query GetItem($hideName: Boolean!) {
  item(id: "foo") {
    id
    name @skip(if: $hideName)
  }
}
```

## Type system directives

Type system directives are applied in your schema. Absinthe provides three
built-in type system directives: `@deprecated`, `@specifiedBy`, and `@oneOf`.

### `@deprecated`

Marks a field, argument, input field, or enum value as no longer supported, with
an optional reason.

The most convenient way to apply it is with the `deprecate` option when defining
a field or enum value:

- Provide a binary value to give a deprecation reason
- Provide `true` to just mark it as deprecated

```elixir
query do
  field :old_item, :item, deprecate: true
  field :another_old_item, :item, deprecate: "still too old"
end
```

You can also use `deprecate` as a macro inside a block, for instance:

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

> #### Warning {: .warning}
>
> Deprecated fields and enum values are not reported by default during
> [introspection](introspection.md).

### `@specifiedBy`

Provides a URL pointing to a specification for a custom scalar type. Apply it
with the `directive` macro inside a `scalar` block, passing the `url` argument:

```elixir
scalar :uuid do
  directive :specified_by, url: "https://tools.ietf.org/html/rfc4122"

  parse &decode_uuid/1
  serialize &encode_uuid/1
end
```

This produces the following in the GraphQL schema:

```graphql
scalar UUID @specifiedBy(url: "https://tools.ietf.org/html/rfc4122")
```

See the [Custom Scalar Types](custom-scalars.md) guide for more on defining
scalars.

### `@oneOf`

Marks an input object as a *OneOf Input Object*: a special variant of an input
object where exactly one field must be set and non-null, all others being
omitted. It's useful for modelling an input that may be one of several
mutually-exclusive options, such as looking something up by *either* an ID *or* a
name.

Apply it with the `directive` macro inside an `input_object` block:

```elixir
input_object :item_lookup do
  directive :one_of

  field :id, :id
  field :name, :string
end
```

This produces the following in the GraphQL schema:

```graphql
input ItemLookup @oneOf {
  id: ID
  name: String
}
```

There are two requirements when applying `@oneOf`, both validated when the schema
is compiled:

- The input object must define **more than one field**.
- **All of its fields must be nullable**---you cannot wrap a field in
  `non_null/1`, because marking a field as required would contradict the rule
  that exactly one field is provided.

When a query is executed, Absinthe validates that exactly one field is supplied
and that its value is non-null---whether provided inline or through variables.
The following is valid because exactly one field is set:

```graphql
{
  item(lookup: { id: "foo" }) {
    name
  }
}
```

Each of these is rejected, because zero or more than one field is set (or the
single field is explicitly null):

```graphql
{ item(lookup: { id: "foo", name: "Foo" }) { name } }  # more than one field
{ item(lookup: { id: null }) { name } }                # field is null
{ item(lookup: {}) { name } }                          # no field set
```

OneOf Input Objects are exposed through introspection via the `isOneOf` field on
the input type, so clients and tooling can detect them:

```graphql
{
  __type(name: "ItemLookup") {
    kind
    isOneOf
  }
}
```
