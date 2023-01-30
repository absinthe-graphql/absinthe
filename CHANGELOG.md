# Changelog

## 1.7.0

- POTENTIALLY BREAKING Bug Fix: [Validate variable usage in according to spec](https://github.com/absinthe-graphql/absinthe/pull/1141). This could break incoming documents previously considered valid. Skip the `Absinthe.Phase.Document.Arguments.VariableTypesMatch` phase to avoid this check. See `Absinthe.Pipeline` on adjusting the document pipeline.

- Feature: [Add GraphQL document formatter](https://github.com/absinthe-graphql/absinthe/pull/1114)
- Bug Fix: [Fix Phase.Schema.Validation.InputOutputTypesCorrectlyPlaced not applied to SDL schema's](https://github.com/absinthe-graphql/absinthe/pull/1142/files)
- Bug Fix: [Use inspect/1 to safely encode bad binary samples](https://github.com/absinthe-graphql/absinthe/pull/1121)
- Bug Fix: [key :is_type_of not found on Interface ](https://github.com/absinthe-graphql/absinthe/issues/1077)
- Bug Fix: [Validate object/interfaces implement all transitive interfaces](https://github.com/absinthe-graphql/absinthe/pull/1127)
- Bug Fix: [Fix check unknown types to also cover wrapped types](https://github.com/absinthe-graphql/absinthe/pull/1138) This could break incoming documents previously considered valid. Skip the `Absinthe.Phase.Validation.KnownTypeNames` phase to avoid this check. See `Absinthe.Pipeline` on adjusting the document pipeline.
- Bug Fix: [Validate field names are unique to an object, interface or an input object](https://github.com/absinthe-graphql/absinthe/pull/1135)

## 1.6.7 (Retired)

Originally included the items from 1.7.0, but the spec validation fix was considered
too impactful for a patch release.
## 1.6.6

- Feature: [Update telemetry dependency to stable ~> 1.0](https://github.com/absinthe-graphql/absinthe/pull/1097)
- Feature: [Use makeup_graphql to get GraphQL syntax highlighting in docs](https://github.com/absinthe-graphql/absinthe/pull/1099)
- Bug Fix: [Fix exception when field name contains all invalid characters](https://github.com/absinthe-graphql/absinthe/pull/1096)

## 1.6.5

- Bug Fix: [Fix interface compilation behavior difference between SDL & DSL](https://github.com/absinthe-graphql/absinthe/pull/1091)
- Bug Fix: [Allow SDL syntax to contain union without member types](https://github.com/absinthe-graphql/absinthe/pull/1085)
- Bug Fix: [Account for prototype schema when rendering SDL via mix task](https://github.com/absinthe-graphql/absinthe/pull/1086)
- Feature: Always inline functions when using persistent_term backend.
- Feature: [Support optional open ended scalars](https://github.com/absinthe-graphql/absinthe/pull/1069)

## 1.6.4

- Feature: [Compress registry tables by default](https://github.com/absinthe-graphql/absinthe/pull/1058)
- Bug Fix: [Fix compilation deadlocks on type imports](https://github.com/absinthe-graphql/absinthe/pull/1056)
- Bug Fix: [Raise a better error when string serialization fails](https://github.com/absinthe-graphql/absinthe/pull/1062)

## 1.6.3

- Bug Fix: [Fix unicode bug when encoding parse error](https://github.com/absinthe-graphql/absinthe/pull/1044)

## 1.6.2

- Bug Fix: [Fix regression in SDL rendering for enum values](https://github.com/absinthe-graphql/absinthe/pull/1041)

## 1.6.1

- Feature: [Improved serialization failure messages](https://github.com/absinthe-graphql/absinthe/pull/1033)
- Bug Fix: [Render null default values in SDL](https://github.com/absinthe-graphql/absinthe/pull/1032)
- Bug Fix: [Reduce memory usage of Schema.Manager](https://github.com/absinthe-graphql/absinthe/pull/1037)

## 1.6.0

- Feature: [Interfaces can now implement Interfaces](https://github.com/absinthe-graphql/absinthe/pull/1012), matching the latest spec
- Feature: Support for the [`repeatable` directive](https://github.com/absinthe-graphql/absinthe/pull/999)
- Feature: Enable [rendering](https://github.com/absinthe-graphql/absinthe/pull/1010) of Type System Directives in SDL based schemas.
- Feature: Correctly match [Introspection type specs](https://github.com/absinthe-graphql/absinthe/pull/1017)
- Bug Fix: Restore dynamic [description support](https://github.com/absinthe-graphql/absinthe/pull/1005) (Note: the `description`s are evaluated once --- at compile time)
- Bug Fix: Restore dynamic [default_value support](https://github.com/absinthe-graphql/absinthe/pull/1026) (Note: the `default_value`s evaluated once --- at compile time)
- Bug Fix: Restore dynamic [Enum value support](https://github.com/absinthe-graphql/absinthe/pull/1023) (Note: the `value` is evaluated once --- at compile time)
- Bug Fix: [Interface nullability](https://github.com/absinthe-graphql/absinthe/pull/1009) corrections
- Bug Fix: Fix [field listing for Inputs](https://github.com/absinthe-graphql/absinthe/pull/1015) that import fields
- Bug Fix: Properly [trim all descriptions](https://github.com/absinthe-graphql/absinthe/pull/1014) no matter the mechanism used to specify them
- Bug Fix: Fix incorrect specification of [`__TypeKind`](https://github.com/absinthe-graphql/absinthe/pull/1019)
- Bug Fix: Better match [introspection schema specification](https://github.com/absinthe-graphql/absinthe/pull/1029)
- Bug Fix: Add missing value to [`__DirectiveLocation`](https://github.com/absinthe-graphql/absinthe/pull/1020)
- Bug Fix: Fix [compilation problems with `import_types`](https://github.com/absinthe-graphql/absinthe/pull/1022)
- Bug Fix: Reduce [memory consumption of Subscriptions](https://github.com/absinthe-graphql/absinthe/pull/1006)

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
