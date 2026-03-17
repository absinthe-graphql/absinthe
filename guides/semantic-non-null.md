# Semantic Non-Null

> **Note:** The `@semanticNonNull` directive is a proposed RFC from the [GraphQL Nullability Working Group](https://github.com/graphql/nullability-wg) and is not yet part of the finalized GraphQL specification. The implementation may change as the proposal evolves.

## Overview

The `@semanticNonNull` directive decouples nullability from error handling. It indicates that a field's resolver never intentionally returns null, but null may still be returned due to errors.

This allows clients to understand which fields may be null only due to errors versus fields that may intentionally be null.

## Enabling the Directive

Since `@semanticNonNull` is a proposed-spec feature, you must explicitly opt-in by importing the directive in your schema:

```elixir
defmodule MyApp.Schema do
  use Absinthe.Schema

  # Import the proposed-spec @semanticNonNull directive
  import_types Absinthe.Type.BuiltIns.SemanticNonNull

  query do
    # ...
  end
end
```

Without this import, the `@semanticNonNull` directive will not be available in your schema.

## Basic Usage

### Using the Directive

Apply the directive to field definitions:

```elixir
object :user do
  field :id, non_null(:id)

  # This field is semantically non-null - it only returns null on errors
  field :name, :string do
    directive :semantic_non_null
  end

  # This field may intentionally be null (no @semanticNonNull)
  field :nickname, :string
end
```

### Shorthand Notation

Absinthe provides a shorthand for applying `@semanticNonNull`:

```elixir
object :user do
  # Using shorthand notation
  field :name, :string, semantic_non_null: true

  # For list fields, specify levels
  field :posts, list_of(:post), semantic_non_null: [0, 1]
end
```

## The Levels Argument

The `levels` argument specifies which levels of the return type are semantically non-null:

- `[0]` (default) - The field itself is semantically non-null
- `[1]` - For list fields, the list items are semantically non-null
- `[0, 1]` - Both the field and its items are semantically non-null

### Examples

```elixir
object :user do
  # The name field is semantically non-null
  field :name, :string, semantic_non_null: true  # Same as [0]

  # The posts list may be null, but items are semantically non-null
  field :posts, list_of(:post), semantic_non_null: [1]

  # Both the friends list AND its items are semantically non-null
  field :friends, list_of(:user), semantic_non_null: [0, 1]
end
```

## Introspection

The directive adds introspection fields to `__Field`:

```graphql
{
  __type(name: "User") {
    fields {
      name
      isSemanticNonNull
      semanticNonNullLevels
    }
  }
}
```

Response:

```json
{
  "data": {
    "__type": {
      "fields": [
        {
          "name": "name",
          "isSemanticNonNull": true,
          "semanticNonNullLevels": [0]
        },
        {
          "name": "nickname",
          "isSemanticNonNull": false,
          "semanticNonNullLevels": null
        }
      ]
    }
  }
}
```

## Client Considerations

Clients can use `@semanticNonNull` information to:

- Automatically throw errors when semantically non-null fields return null
- Generate stricter types in code generation tools
- Improve developer experience with better nullability handling

Apollo Client and other modern GraphQL clients are adding support for this directive. Consult your client's documentation for specific integration details.

## See Also

- [GraphQL Nullability Working Group](https://github.com/graphql/nullability-wg)
- [Errors Guide](errors.md) for error handling in Absinthe
