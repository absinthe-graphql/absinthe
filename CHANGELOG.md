# Changelog

For changes pre v1.5 see the [v1.4](https://github.com/absinthe-graphql/absinthe/blob/v1.4/CHANGELOG.md) branch

## v1.5.0-alpha.0

Alpha 0 note: 1.5.0 alpha is safe to use on existing schemas. However, there are no schema validations at the moment, so when writing new ones you may get undefined behaviour if you write an invalid schema. 

- COLUMN NUMBERS! The Absinthe Lexer has been rewritten using `nimble_parsec` and now Absinthe includes column information.
- Complete rewrite of schema internals. This fixes a number of long standing bugs, and provides a variety of new features
- Feature: SDL support
- Feature: Schema decorators
- Breaking Change: `default_value: DateTime.utc_now()` will have its time set at compile time. IE: DON'T DO THIS. It only worked by accident before anyway, and now it no longer works, which is correct.
- Breaking change: added `node_name/0` callback to `Absinthe.Subscription.PubSub` behaviour. To retain old behaviour, implement this callback to return `Kernel.node/0`.
