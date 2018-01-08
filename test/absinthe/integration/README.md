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
`execution/`. Group by type of thing, not specific testing
context. For instance, if you wanted to add an integration test around
the use of the `null` input type literal, when used as an element of a
list (that is a non-nullable argument), it's better to name it
something like
`execution/input_types/null/non_nullable_arg_list_element_literal.graphql`,
not
`execution/input_types/null/non_nullable_arg/list/element/literal.graphql`);
it's easier to scan the various permutations in a single directory of
files.
