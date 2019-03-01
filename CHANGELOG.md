# Changelog

## v1.4.16

- Bug Fix: Remove build artifact from hex release.

## v1.4.15

- Bug Fix: Correctly compute complexity for documents with inline fragments.

## v1.4.14

- Bug Fix: Add missing `Absinthe.Subscription.child_spec/1` function 
- Bug Fix: Pass options along when exporting schema json.

## v1.4.13

- Enhancement: Support for Elixir 1.7.0
- Bug Fix: Fixes performance issue where deeply nested inputs used exorbitant amounts of memory.

## v1.4.12

- Bug Fix: Fixes shard routing issue with subscription pubsub
- Bug Fix: Ensure project is compiled when running absinthe mix tasks

## v1.4.11

- Bug Fix: `import_types Foo.{Bar, Baz}` syntax should avoid compilation order issues
- Enhancement: Context and root value handling is broken out now to facilitate improvements in Absinthe Plug

## v1.4.10

- Bug Fix: Proper GraphQL context handling in subscriptions

## v1.4.9

- Doc Improvements
- Formatter Improvements
- Bug Fix: Dataloader won't explode if a given pass uses only already cached values

## v1.4.7

- Bug Fix: Update `result_selection_t` typespec.
- Feature: Added `.formatter.exs` for use with Elixir v1.6's `mix format`.
- Chore: Type fixes and updated links in README and documentation.

## v1.4.6

- Feature: Support for `meta` macro keyword list args.

## v1.4.5

- Feature: Support for `"""`-quoted block strings, as defined in the GraphQL Specification (See facebook/graphql#327).

## v1.4.4

- Bug Fix: fix where self referential interface type would cause infinite loop when introspecting.

## v1.4.3

- Bug Fix: fix regression where types only connected to the root query via interfaces wouldn't show up in GraphiQL.

## v1.4.2

- Bug Fix: `null` can be properly used for enum inputs.

## v1.4.1

- Bug Fix: fix regression where interfaces wouldn't show up in GraphiQL unless used as a field return type.

## v1.4.0

- Bug Fix: Ensured types that aren't used by the schema's root types aren't reported by introspection
- Internal Change: Added `Absinthe.Schema.used_types`, `Absinthe.Schema.introspection_types/1`, and `Type.introspection?/1`

- Enhancement: Subscriptions! See the Absinthe.Phoenix project for getting started info.
- Enhancement: Null literal support [as laid out in the October 2016 GraphQL Specification](http://facebook.github.io/graphql/#sec-Null-Value)
- Enhancement: Errors now include path information. This path information can be accessed in resolvers via `Absinthe.Resolution.path/1`

- Breaking Change: Default middleware applied eagerly. If you're changing the default resolver, you WILL need to consult: https://github.com/absinthe-graphql/absinthe/pull/403 See: https://hexdocs.pm/absinthe/1.4.0-rc.3/Absinthe.Schema.html#replace_default/4

- Breaking Change: Plugins receive an `%Absinthe.Blueprint.Execution{}` struct instead of the bare accumulator. This makes it possible for plugins to set or operate on context values. Upgrade you plugins! Change this:
  ```
  def before_resolution(acc) do
    acc = # doing stuff to the acc here
  end
  def after_resolution(acc) do
    acc = # doing stuff to the acc here
  end
  def pipeline(pipeline, acc) do
    case acc do
      # checking on the acc here
    end
  end
  ```
  to
  ```
  def before_resolution(%{acc: acc} = exec) do
    acc = # doing stuff to the acc here
    %{exec | acc: acc}
  end
  def after_resolution(%{acc: acc} = exec) do
    acc = # doing stuff to the acc here
    %{exec | acc: acc}
  end
  def pipeline(pipeline, exec) do
    case exec.acc do
      # checking on the acc here
    end
  end
  ```
  The reason for this is that you can also access the `context` within the `exec` value. When using something like Dataloader, it's important to have easy to the context

- Breaking Change: Errors returned from resolvers no longer say "In field #{field_name}:". The inclusion of the path information obviates the need for this data, and it makes error messages a lot easier to deal with on the front end.

- Internal Change: `Absinthe.Blueprint.Document.Resolution` => `Absinthe.Blueprint.Execution`. See https://github.com/absinthe-graphql/absinthe/pull/409 for details.

## v1.3.2

- Bug Fix: Handle OTP 20.0 warnings.
- Bug Fix: Ensure `%Absinthe.Resolution{}` struct can be inspect inside `resolve_type` and similar.
- Bug Fix: Handle `nil` return values from `resolve_type`

## v1.3.1

- Enhancement: Improved nested fragment handling when merging is required.
- Enhancement: Performance improvements, particularly for documents containing fragments
- Enhancement: `Absinthe.Resolution.project/1,2` which returns the child fields under the current field. This is an improvement upon the previous recommendation, which was to get child fields via using internal data structures found in info, and required manual handling of type conditions.

- NOTE: If you were previously computing subfields by looking at `%Absinthe.Blueprint.Document.Field{}` internals, do note that their structure has changed a little. Notably, there is no longer a `:fields` key.

## v1.3.0

- Added `Absinthe.Logger` -- adds configurable pipeline and variable logging
  with filtering support (filters "token" and "password" by default). Used by
  the `absinthe_plug` package.

- Enhancement: Added resolution middleware. See the `Absinthe.Middleware`
  moduledocs.
- Enhancement: Middleware can be used to change the context. Use this
  judiciously.
- Enhancement: Added built-in date and time types. Simply `import_types
  Absinthe.Type.Custom` in your schema to use.
- Enhancement: Error tuple values can now be anything that's compatible with
  `to_string/1`
- Enhancement: Substantial performance improvements for type conditions and
  abstract type return values
- Enhancement: Added `Absinthe.Pipeline.replace/3` for easier modification of
  pipeline phases.
- Enhancement: Scalar and Enum serialization moved to the
  `Absinthe.Phase.Document.Result` phase, making customization of serialization
  easier.

- Bug Fix: All interfaces an object claims to implement are checked at compile
  time, instead of just the first.

- Breaking change: Plugins have been replaced by middleware, see the middleware
  docs.
- Breaking change: `default_resolve` is no longer valid, see
  `Absinthe.Middleware`.
- Breaking change: A root `query` object is now required, per the GraphQL spec.
- Breaking change: `Absinthe.Type.Interface.implements/2` is now `implements/3`
  with the last argument being the schema.

- Cleanup: Undocumented module `InterfaceMap` removed as it was no longer being
  used.

## v1.2.6

- Enhancement: Query complexity analysis!
- Bug fix: Fields with runtime errors are presented with `null` values in the result data instead of elided entirely.

## v1.2.5

- Enhancement: Scalar type parse functions can access the context. This enables
uploaded files with Absinthe.Plug

## v1.2.4
- Enhancement: Complex errors. You can now return `{:error, %{message: "...", other_key: value}}`
- Bug Fix: Invalid Arguments on a field that is under a list field doesn't error.
- Bug Fix: Deeper fragment merging.

## v1.2.3
- Bug Fix: When there are no arguments, an empty map should be passed to the resolution functions not `nil`

## v1.2.2
- Enhancement: Enable `import_fields` for input objects. In the future we will
enforce that `input_objects` can only import fields from other `input_objects`.
- Enhancement: Improved exception when returning `nil` from a field marked `non_null`
- Enhancement: Allow returning complex errors from resolution functions.
- Enhancement: Minor tweaks to support the in-progress Elixir 1.4 release
- Bug fix: Handle fragments on the root query and root mutation types
- Bug fix: Handle errors on variables when no operation name.
- Bug fix: input objects passed in as variables with missing internal fields marked non null are correctly caught
- Assorted other bug fixes

## v1.2.1

- Stricter, spec-compliant scalar parsing rules (#194)
- Bug fix: Fixes to complex resolution using abstract types (#197) (#199)
- Bug fix: Fix escaped characters in input literals (#165) (#202)
- Bug fix: Fix regression where nested list input types did not work (#205)

## v1.2

## Overview

Absinthe now generates a richer "intermediate representation" of query
documents (see `Absinthe.Blueprint`) from the document AST. This representation
then serves as the data backbone for processing during later phases.

Rather than the integrated validation-during-execution approach used in
previous versions-- and rather than using a few "fat" phases (eg, "Parsing",
"Validation", "Execution") as in other implementations -- Absinthe treats
all operations (parsing, each individual validation, field resolution, and
result construction) as a pipeline (see `Absinthe.Pipeline`) of discrete
and equal phases. This allows developers to insert, remove, switch-out, and
otherwise customize the changes that occur to the intermediate representation,
and how that intermediate representation turns into a result. Future releases
will further this model and continue to make it easier to modify Absinthe's
processing to support the unique needs of developers.

### Breaking Changes

#### Deprecations and Errors

Absinthe no longer automatically adds deprecations to result
errors. (Although this is possible with the addition of custom
phases.)

#### More Strict Input Value Parsing

Absinthe now more closely adheres to the GraphQL specification's rules
about input value coercion, to include:

- Int: Disallowing automatic coercion of, eg, `"1"` to `1`
- String: Disallowing automatic coercion of, eg, `1` to `"1"`
- Enum: Disallowing quoted values, eg, `"RED"` vs `RED`

Furthermore scalar type `parse` functions now receive their value as
`Absinthe.Blueprint.Input.t` structs. If you have defined your own
custom scalar types, you may need to modify them; see
`lib/absinthe/type/built_ins/scalars.ex` for examples.

#### Validation Errors Prevent Resolution

In accordance with the GraphQL Specification, if any errors are added
during document validation, no resolution will occur. In the past,
because validation was done on-the-fly during resolution, partial
resolution, just returning `null` for fields (in a way that would be
invalid, according to the spec) was possible.

(Notably, this release includes a very large number of new document
validations.)

#### No AST Nodes in Resolution

The raw AST nodes are no longer provided as part of the "info" argument passed
to resolve functions. If you have built logic (eg, Ecto preloading) based on
the AST information, look at the `definition` instead, which is a Blueprint
`Field` struct containing a `fields` array of subfields. These fields have
passed validation and have been flattened from any fragments that may have
been used in the original document (you just may want to pay attention to
each field's `type_conditions`).

#### List Coercion

Fields and arguments with list types are now automatically coerced if given a
single item. For example if you have `arg :ids, list_of(:id)` Absinthe will coerce
a document like `foo(ids: 1)` into `foo(ids: [1])`.

This is also true for resolution functions. If your field has a return type of
`list_of(:user)` and your resolution function returns `{:ok, %User{}}`, the value
is wrapped. It is as though you returned `{:ok, [%User{}]}`.

#### Simpler Adapters

Adapters now only use `to_internal_name/2` and `to_external_name/2` as the
`Absinthe.Blueprint` intermediate representation and schema application
phase removes the need for whole document conversion. If you have defined
your own adapter, you may need to modify it.

#### Mix Task Removal

The IDL generating mix task (`absinthe.schema.graphql`) has been temporarily
removed (due to the extent of work needed to modify it for this release), but
it will reappear in a future release along with integrated schema compilation
from GraphQL IDL.

### Other Changes

#### Resolution Functions

Support for 3-arity resolution functions. Resolution functions accepting 3
arguments will have the current "source" (or parent) object passed as the
first argument. 2-arity resolution functions will continue to be supported.

The following resolutions functions are equivalent:

```elixir
fn source, args, info -> {:ok, source.foo} end
fn args, %{source: source} -> {:ok, source.foo} end
```

#### Resolution Plugins (+ Async & Batching)

v1.2 features a Resolution Plugin mechanism. See the docs in the
`Absinthe.Resolution.Plugin` module for more information.

#### Resolution Info

In previous versions, the last argument to resolution functions was an
`Absinthe.Execution.Field` struct. It is now an `Absinthe.Resolution` struct.
While the struct has most of the same information available, the AST nodes
is no longer provided. See "Breaking Changes" above.

#### Custom Type Metadata

To further support extensibility, types and fields can be annotated using the
`Absinthe.Schema.Notation.meta/2` macro, and metadata extracted using
`Absinthe.Type.meta/1` and `Absinthe.Type.meta/1`. This metadata facility has
been added for objects, input objects, enums, scalars, unions, interfaces, and
fields.

## v1.1.7

### Bugfixes

- Fix execution of nested fragment spreads with abstract condition types.

## v1.1.6

### Bugfixes

- Support adapting InterfaceDefinition structs; caused a warning when
  running the `absinthe.schema.graphql` mix task.
- Fix missing newline after scalar type definitions in IDL output by
  the `absinthe.schema.graphql` mix task.

## v1.1.5

### Bugfixes

- Correctly stringify serialized default values when introspecting

## v1.1.4

### Bugfixes

- Fix bug where fragments with abstract type conditions were not applied in some cases
- Correctly serialize default values based on the underlying type for introspection

## v1.1.3

### Bugfixes

- Fix regression where documents containing multiple operations could not have the operation selected
- Fix issues with returning union types.
- Fix bug where field names inside argument errors were not returned in the adapted format.

### Mix Tasks

- `absinthe.schema.json` now requires schema to be given as an `--schema`
  option, but supports the `:absinthe` `:schema` application configuration
  value.
- `absinthe.schema.graphql` task added.

## v1.1.2

### Bugfixes

- Include `priv/` in package for `absinthe.schema.json` task.

## v1.1.1

### Bugfixes

- Variables with input objects and lists inside other input objects work properly.

## v1.1.0

The v1.1.0 release bundles a bunch of bugfixes and expanded features for
Absinthe, especially around:

- Support for expanding notation in other packages
- Complex arguments and variables
- An `absinthe.schema.json` mix task to extract a JSON representation of
  a schema for additional tooling (especially [Absinthe.Relay](https://github.com/absinthe-graphql/absinthe_relay).
- Custom default resolvers, and more!

In terms of breaking changes, there is one you should know about:

### Enum values

As of v1.1.0, Absinthe, by default, adheres to the specification recommendation
that enum values be provided in ALLCAPS. If you have existing enum definitions
in your schema that have not explicitly declared how values should be accepted,
see the documentation for the `Absinthe.Schema.Notation.enum/3` macro,
especially the use of `:as`, eg:

```elixir
enum :color do
  value :red, as: "r"
  value :green, as: "g"
  value :blue, as: "b"
end
```

## v1.0.0

Our v1.0.0 release offers an entirely new way of build schemas. This new
approach uses macros -- to simplify the visual complexity of schemas, provide
more comprehensive feedback on correctness, and increase performance, since we
can now execute any necessary checks and transformations during compilation.

### Type Definitions

Here's an example of an object definition in the _old_ notation style:

```elixir
@absinthe :type
def car do
  %Absinthe.Type.Object{
    description: "A car",
    fields: fields(
      picture_url: [
        type: :string,
        description: "Photo URL"
        args: args(
          size: [
            type: non_null(:string),
            description: "The size of the photo"
          ]
        ),
        resolve: fn %{size: size}, %{source: car} ->
          {:ok, "http://images.example.com/cars/#{car.id}-#{size}.jpg"}
        end
      ]
    )
  }
end
```

Here it is in the new style:

```elixir
@desc "A car"
object :car do

  @desc "Photo URL"
  field :picture_url, :string do

    @desc "The size of the photo"
    arg :size, non_null(:string)

    resolve fn %{size: size}, %{source: car} ->
      {:ok, "http://images.example.com/cars/#{car.id}-#{size}.jpg"}
    end

  end

end
```

In general, attributes of types are now available as nested macros
(eg, `resolve` above), and attributes that are plural have a singular form
(eg, previously you passed a `:fields` value and used a `fields/1` convenience
function; now you use the singular `field` macro to define each individual
field).

### Type Modules

In the past, this is how you would import types from another module:

```elixir
defmodule Types do
  use Absinthe.Type.Definitions

  # ...
end

defmodule Schema do
  use Absinthe.Schema, type_modules: [Types]

  # ...
end
```

This is how it is done now:

```elixir
defmodule Types do
  use Absinthe.Schema.Notation

  # ...
end

defmodule Schema do
  use Absinthe.Schema

  import_types Types

  # ...
end
```

## More Information

Since much of the moving parts have been changed, please read through the
documentation generally -- and recommend any specific instructions that you
think make sense to be included in the changelog.

## v0.5.0

The following changes are required if you're upgrading from the previous version:

### Resolution Functions

The second argument passed to resolution functions has changed from
`Absinthe.Execution.t` to a flatter, simpler data structure,
`Absinthe.Resolution.t`. This struct will be a more carefully curated
selection of metadata and match more closely to values in the JS
reference implementation.

See the typedoc for information about `Absinthe.Resolution.t`, and change
any advanced resolvers to use this new struct. The most likely change will be
the use of `source` instead of `resolution.target`.

### v0.4.0

The following changes are required if you're upgrading from the previous version:

### Enums

Instead of providing a map to `:values`, use the `values/1` convenience function from `Absinthe.Type.Definitions`:

Before:

```elixir
%Type.Enum{
  values: %{
    "foo" => :f,
    "bar" => :b
  }
}
```

Now:

```elixir
%Type.Enum{
  values: values(
    foo: [value: :f],
    bar: [value: :b]
  )
}
```

This allows us to support `:description` and deprecated values as used elsewhere. See `Absinthe.Type.Enum` for more information.

## v0.3.0

The following changes are required if you're upgrading from the previous version:

### Adapters

If using `Absinthe.Adapters.Passthrough`, you must manually configure it,
[as explained in the README](./README.md#adapters), now that the default has
changed to `Absinthe.Adapters.LanguageConventions`.
