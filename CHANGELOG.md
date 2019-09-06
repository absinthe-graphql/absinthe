# Changelog

For changes pre-v1.5 see the [v1.4](https://github.com/absinthe-graphql/absinthe/blob/v1.4/CHANGELOG.md) branch.

## v1.5.0 (Beta)

- Feature: SDL directives, other improvements
- Feature: Output rendered SDL for a schema
- Documentation: Testing guide, numerous fixes and updates
- Breaking Change: Scalar outputs are now type checked and will raise exceptions
if the result tries to send the wrong data type in the result.

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
