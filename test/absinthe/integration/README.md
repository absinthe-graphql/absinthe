# Integration Tests

Before adding integration tests, please read:

- The module documentation for `Absinthe.IntegrationCase`, so you know
  the expected format for `.graphql` and `.exs` files.
- The contents of `test/absinthe/integration_test.exs`, which sets the
  default schema and contains custom assertion logic for some tests.

## Directory Structure

Top-level directories should be pretty self-explanatory. If your
integration test is focused on parsing or validation errors (ie,
documents that don't get executed), put it in `parsing/` or
`validation/`, respectively. If your integration test has a passing
(executed) scenario, put it in `execution/`.

Try to keep the directory structure fairly flat under
`execution/`. Create subdirectories for type of thing, not specific testing
context. Try to keep to existing file naming conventions.

Feel free to use GraphQL type names, prefixed with `type_` in
filenames (describing types longhand is too verbose/inexact). Use the
example type `T` to indicate any type. (Example:
`execution/input_types/null/literal_as_type_[T!]!_element.graphql`)
