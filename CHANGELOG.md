# Changelog

## 1.5.5

- Bug Fix: Fix for `nil` in [`ArgumentsOfCorrectType` suggestions](https://github.com/absinthe-graphql/absinthe/pull/1000)

## 1.5.4

- Feature: Ensure [stable ordering in introspection results](https://github.com/absinthe-graphql/absinthe/pull/997).
- Bug Fix: Fix [rendering of interfaces in SDL](https://github.com/absinthe-graphql/absinthe/pull/979)
- Bug Fix: Properly [escape single line descriptions in SDL](https://github.com/absinthe-graphql/absinthe/pull/968)
- Bug Fix: Fix [`:meta` on fields](https://github.com/absinthe-graphql/absinthe/pull/973)
- Bug Fix: Validate that [DirectivesMustBeValid](https://github.com/absinthe-graphql/absinthe/pull/954)
- Bug Fix: Handle [default value rendering with partial field set](https://github.com/absinthe-graphql/absinthe/pull/998)

## 1.5.3

- Bug Fix: Handle null propagation with `non_null(list_of(non_null(type)))` properly
- Bug Fix: Fix [double escaping issue](https://github.com/absinthe-graphql/absinthe/pull/962) with string literal arguments.

## 1.5.2

- Bug Fix: Fix issue with persistent term backend.

## 1.5.1

- Bug Fix: Enable hydrating resolve_type on unions. #938
- Bug Fix: #922

## v1.5.0 (Rc)

- Breaking Bug Fix: Variable types must align exactly with the argument type. Previously
Absinthe allowed variables of different types to be used by accident as long as the data parsed.
- Feature (Experimental): `:persistent_term` based schema backend
- Breaking Change: `telemetry` event keys [changed](https://github.com/absinthe-graphql/absinthe/pull/901) since the beta release.

## v1.5.0 (Beta)
- Feature: SDL directives, other improvements
- Feature: Output rendered SDL for a schema
- Feature: Substantially lower subscription memory usage.
- Documentation: Testing guide, numerous fixes and updates
- Breaking Change: Scalar outputs are now type checked and will raise exceptions if the result tries to send the wrong data type in the result.
- Breaking Change: `telemetry` event names [changed](https://github.com/absinthe-graphql/absinthe/pull/782) from the `alpha` to match an emerging naming convention for tracing.
- Breaking Change: Added phase to check validity of field names according to GraphQL spec. Might break existing schema's. Remove the `Absinthe.Phase.Schema.Validation.NamesMustBeValid` from the schema pipeline if you want to ignore this.
- Breaking Change: To match the GraphQL spec, we [no longer](https://github.com/absinthe-graphql/absinthe/pull/816) add a non-null error when a resolver on a non-null field explicitly returns its own error.
- Breaking Change: Removed `Absinthe.Traversal` module

## v1.5.0 (Alpha)

Alpha 0 note: 1.5.0 alpha is safe to use on existing schemas. However, there are no schema validations at the moment, so when writing new ones you may get undefined behaviour if you write an invalid schema.

- COLUMN NUMBERS! The Absinthe Lexer has been rewritten using `nimble_parsec` and now Absinthe includes column information.
- Complete rewrite of schema internals. This fixes a number of long standing bugs, and provides a variety of new features
- Feature: SDL support
- Feature: Schema decorators
- Feature: Customizable subscription de-duplification. See: https://github.com/absinthe-graphql/absinthe/blob/master/guides/subscriptions.md#de-duplicating-updates
- Feature: Built-in `telemetry` instrumentation (https://github.com/beam-telemetry/telemetry)
- Breaking Change: `default_value: DateTime.utc_now()` will have its time set at compile time. IE: DON'T DO THIS. It only worked by accident before anyway, and now it no longer works, which is correct.
- Breaking change: added `node_name/0` callback to `Absinthe.Subscription.PubSub` behaviour. To retain old behaviour, implement this callback to return `Kernel.node/0`.

## v1.4

For changes pre-v1.5 see the [v1.4](https://github.com/absinthe-graphql/absinthe/blob/v1.4/CHANGELOG.md) branch.
