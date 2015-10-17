## Type Object Names

Instead of `GraphQLFoo` or `GraphQLFooType`, we use `ExGraphQL.Types.Foo`.

We also convert `camelCase` names to `snake_case`.

## Field Values

The `fields` type of both `ExGraphQL.Types.Interface` and
`ExGraphQL.Types.Object` is a map rather than a function that returns a map.
