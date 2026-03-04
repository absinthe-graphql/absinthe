# Changelog

## Unreleased

### Features

* **draft-spec:** Add `@defer` and `@stream` directives for incremental delivery ([#1377](https://github.com/absinthe-graphql/absinthe/pull/1377))
  - **Note:** These directives are still in draft/RFC stage and not yet part of the finalized GraphQL specification
  - **Opt-in required:** `import_directives Absinthe.Type.BuiltIns.IncrementalDirectives` in your schema
  - Split GraphQL responses into initial + incremental payloads
  - Configure via `Absinthe.Pipeline.Incremental.enable/2`
  - Resource limits (max concurrent streams, memory, duration)
  - Dataloader integration for batched loading
  - SSE and WebSocket transport support
* **subscriptions:** Support `@defer` and `@stream` in subscriptions
  - Subscriptions with deferred content deliver multiple payloads automatically
  - Existing PubSub implementations work unchanged (calls `publish_subscription/2` multiple times)
  - Uses standard GraphQL incremental delivery format that clients already understand
* **streaming:** Unified streaming architecture for queries and subscriptions
  - New `Absinthe.Streaming` module consolidates shared abstractions
  - `Absinthe.Streaming.Executor` behaviour for pluggable task execution backends
  - `Absinthe.Streaming.TaskExecutor` default executor using `Task.async_stream`
  - `Absinthe.Streaming.Delivery` handles pubsub delivery for subscriptions
  - Both query and subscription incremental delivery share the same execution path
* **executors:** Pluggable task execution backends
  - Implement `Absinthe.Streaming.Executor` to use custom backends (Oban, RabbitMQ, etc.)
  - Configure via `@streaming_executor` schema attribute, context, or application config
  - Default executor uses `Task.async_stream` with configurable concurrency and timeouts
* **telemetry:** Add telemetry events for incremental delivery
  - `[:absinthe, :incremental, :delivery, :initial]` - initial response
  - `[:absinthe, :incremental, :delivery, :payload]` - each deferred/streamed payload
  - `[:absinthe, :incremental, :delivery, :complete]` - stream completed
  - `[:absinthe, :incremental, :delivery, :error]` - error during streaming
* **monitoring:** Add `on_event` callback for custom monitoring integrations (Sentry, DataDog)

## [1.9.0](https://github.com/absinthe-graphql/absinthe/compare/v1.8.0...v1.9.0) (2025-11-21)


### Features

* add GQL sigil to format and lint static GraphQL docs ([#1391](https://github.com/absinthe-graphql/absinthe/issues/1391)) ([3aef283](https://github.com/absinthe-graphql/absinthe/commit/3aef283cb4defafba5d7755f164292ef450f8f71))

## [1.8.0](https://github.com/absinthe-graphql/absinthe/compare/v1.7.11...v1.8.0) (2025-11-05)


### Features

* **spec:** Add support for `[@one](https://github.com/one)Of` directive ([#1386](https://github.com/absinthe-graphql/absinthe/issues/1386)) ([01e8e4b](https://github.com/absinthe-graphql/absinthe/commit/01e8e4b67dd8c380094cb6cf66d2a7f6da661a68))


### Bug Fixes

* **typespec:** Absinthe.Phase.Subscription.SubscribeSelf.run/2 ([#1384](https://github.com/absinthe-graphql/absinthe/issues/1384)) ([4230cc4](https://github.com/absinthe-graphql/absinthe/commit/4230cc4a33ec8dc00ae5f8650cb012e652780738))

## [1.7.11](https://github.com/absinthe-graphql/absinthe/compare/v1.7.10...v1.7.11) (2025-10-29)


### Bug Fixes

* SDL rendering for directives with input objects ([#1375](https://github.com/absinthe-graphql/absinthe/issues/1375)) ([02b955c](https://github.com/absinthe-graphql/absinthe/commit/02b955c49e74a25e09aa00d7029d7bdce57e7b81))

## v1.7.10
- Bug Fix: [Set include_deprecated default value to true for backwards compatibility](https://github.com/absinthe-graphql/absinthe/pull/1333)
- Bug Fix: [Rename to TokenLimitEnforcementTest to fix warning](https://github.com/absinthe-graphql/absinthe/pull/1362)
- Bug Fix: [Replace regex with pattern as string to support OTP 28](https://github.com/absinthe-graphql/absinthe/pull/1360)
- Bug Fix: [Use Code.ensure_compiled! at compile time](https://github.com/absinthe-graphql/absinthe/pull/1361)

## v1.7.9
- Feature: [Allow config/2 to send errors in spec compliant format](https://github.com/absinthe-graphql/absinthe/pull/1341)
- Feature: [Add async option to Absinthe.Subscription](https://github.com/absinthe-graphql/absinthe/pull/1329)
- Bug Fix: [Avoid table scans on registry](https://github.com/absinthe-graphql/absinthe/pull/1330)
- Bug Fix: [Unregsiter duplicate (listening to the same topic) subscriptions individually](https://github.com/absinthe-graphql/absinthe/pull/1336)
- POTENTIALLY BREAKING Feature: [Add telemetry event on batch timeout](https://github.com/absinthe-graphql/absinthe/pull/1347). If you want to keep the behavior from 1.7.8, define a telemetry handler and attach it. For example:

```elixir
defmodule MyApp.Telemetry do
  require Logger

  def log_absinthe([:absinthe, :middleware, :batch, :timeout], _, metadata, _) do
    Logger.error("Failed to get batching result in #{metadata.timeout}ms for\nfn: #{inspect(metadata.fn)}")
  end
end

# attach

:telemetry.attach("absinthe-batch-timeout", [:absinthe, :middleware, :batch, :timeout], &MyApp.Telemetry.log_absinthe/4, nil)
```

## 1.7.8

- Bugfix: Fixes an issue where schemas would not find their types, or not be found at all.

## 1.7.7
- POTENTIALLY BREAKING Bug Fix: [Validate variable usage in nested input arguments](https://github.com/absinthe-graphql/absinthe/pull/1290).This could break incoming documents previously considered valid. Skip the Absinthe.Phase.Document.Arguments.VariableTypesMatch phase to avoid this check. See Absinthe.Pipeline on adjusting the document pipeline.
- #1321 resolves telemetry issues
- Various minor dependency versioning tweaks
- Handle Elixir 1.17 warnings

## 1.7.6

- Bugfix: [Handle non_null(list_of(:thing)) with null list elements properly](https://github.com/absinthe-graphql/absinthe/pull/1259)
- Bugfix: [More non null result handling improvements](https://github.com/absinthe-graphql/absinthe/pull/1275)

## 1.7.5

- Feature: Support Dataloader 2.0

## 1.7.4

- Bug Fix: [Bugfix: multiple pushes per client for subscriptions that have a context_id](https://github.com/absinthe-graphql/absinthe/pull/1249)

## 1.7.3

- Bug Fix: [OTP 26 and Elixir 1.15 tweaks](https://github.com/absinthe-graphql/absinthe/pull/1253)
- Bug Fix: [OTP 25 tweaks](https://github.com/absinthe-graphql/absinthe/pull/1253)
- Bug Fix: [Place extra error attributes in error extensions field](https://github.com/absinthe-graphql/absinthe/pull/1215)

## 1.7.2

- Bug Fix: [Validate type references for invalid wrapped types](https://github.com/absinthe-graphql/absinthe/pull/1195)
- Feature: [Add `specifiedBy` type system directive](https://github.com/absinthe-graphql/absinthe/pull/1193)
- Bug Fix: [Object type extensions may be empty](https://github.com/absinthe-graphql/absinthe/pull/1228)
- Bug Fix: [Validate input object not being an Enum](https://github.com/absinthe-graphql/absinthe/pull/1231)
- Bug Fix: [Deduplicate directives when building schema](https://github.com/absinthe-graphql/absinthe/pull/1242)

## 1.7.1
- Breaking Bugfix: [Validate repeatable directives on schemas](https://github.com/absinthe-graphql/absinthe/pull/1179)
- Breaking Bugfix: [Add "Objects must define fields" schema validation](https://github.com/absinthe-graphql/absinthe/pull/1167)
- Bug Fix: [Validate field identifier uniqueness](https://github.com/absinthe-graphql/absinthe/pull/1200)
- Bug Fix: [Validate type references for invalid wrapped types](https://github.com/absinthe-graphql/absinthe/pull/1195)
- Bug Fix: Adds **optional fix** for non compliant built-in scalar Int type. `use Absinthe.Schema, use_spec_compliant_int_scalar: true` in your schema to use the fixed Int type. It is also advisable to upgrade for custom types if you are leveraging the use of integers outside the GraphQl standard. [#1131](https://github.com/absinthe-graphql/absinthe/pull/1131).
- Feature: [Support custom opts in schema pipeline modifiers](https://github.com/absinthe-graphql/absinthe/pull/1214)
- Feature: [Support error tuples when scalar parsing fails](https://github.com/absinthe-graphql/absinthe/pull/1187)
- Feature: [Convert SDL Language.\* structs to SDL notation](https://github.com/absinthe-graphql/absinthe/pull/1160)
- Feature: [Support passing the resolution struct to dataloader helper callbacks](https://github.com/absinthe-graphql/absinthe/pull/1211)
- Feature: [Add support for type extensions](https://github.com/absinthe-graphql/absinthe/pull/1157)
- Bug Fix: [Add type system directives to introspection results](https://github.com/absinthe-graphql/absinthe/pull/1189)
- Bug Fix: [Add `__private__` field to EnumValueDefinition](https://github.com/absinthe-graphql/absinthe/pull/1148)
- Bug Fix: [Fix bug in Schema.**absinthe_types**(:all) for Persistent Term](https://github.com/absinthe-graphql/absinthe/pull/1161)
- Bug Fix: [Fix default enum value check for SDL schema's](https://github.com/absinthe-graphql/absinthe/pull/1188)
- Feature: [Add `import_directives` macro](https://github.com/absinthe-graphql/absinthe/pull/1158)
- Feature: [Support type extensions on schema declarations](https://github.com/absinthe-graphql/absinthe/pull/1176)
- Bug Fix: [Root objects are marked as referenced correctly](https://github.com/absinthe-graphql/absinthe/pull/1186)
- Bug Fix: [Prevent DDOS attacks with long queries](https://github.com/absinthe-graphql/absinthe/pull/1220)
- Feature: [pipeline_modifier option to Absinthe.run/3](https://github.com/absinthe-graphql/absinthe/pull/1221)
- Bug Fix: [Add end_time_mono to telemetry :stop events](https://github.com/absinthe-graphql/absinthe/pull/1174)

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
- Feature: Customizable subscription de-duplification. See: https://github.com/absinthe-graphql/absinthe/blob/main/guides/subscriptions.md#de-duplicating-updates
- Feature: Built-in `telemetry` instrumentation (https://github.com/beam-telemetry/telemetry)
- Breaking Change: `default_value: DateTime.utc_now()` will have its time set at compile time. IE: DON'T DO THIS. It only worked by accident before anyway, and now it no longer works, which is correct.
- Breaking change: added `node_name/0` callback to `Absinthe.Subscription.PubSub` behaviour. To retain old behaviour, implement this callback to return `Kernel.node/0`.

## v1.4

For changes pre-v1.5 see the [v1.4](https://github.com/absinthe-graphql/absinthe/blob/v1.4/CHANGELOG.md) branch.
