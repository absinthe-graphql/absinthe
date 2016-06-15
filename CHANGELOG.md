# Changelog

## v1.1.7

Bugfixes
- Fix execution of nested fragment spreads with abstract condition types.

## v1.1.6

Bugfixes
- Support adapting InterfaceDefinition structs; caused a warning when
  running the `absinthe.schema.graphql` mix task.
- Fix missing newline after scalar type definitions in IDL output by
  the `absinthe.schema.graphql` mix task.

## v1.1.5

Bugfixes
- Correctly stringify serialized default values when introspecting

## v1.1.4

Bugfixes

- Fix bug where fragments with abstract type conditions were not applied in some cases
- Correctly serialize default values based on the underlying type for introspection

## v1.1.3

Bugfixes:

- Fix regression where documents containing multiple operations could not have the operation selected
- Fix issues with returning union types.
- Fix bug where field names inside argument errors were not returned in the adapted format.

Mix Tasks:

- `absinthe.schema.json` now requires schema to be given as an `--schema`
  option, but supports the `:absinthe` `:schema` application configuration
  value.
- `absinthe.schema.graphql` task added.

## v1.1.2

Bugfixes:

- Include `priv/` in package for `absinthe.schema.json` task.

## v1.1.1

Bugfixes:

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

## Enum values

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

## Type Definitions

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

## Type Modules

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
`Absinthe.Execution.Field.t`. This struct will be a more carefully curated
selection of metadata and match more closely to values in the JS
reference implementation.

See the typedoc for information about `Absinthe.Execution.Field.t`, and change
any advanced resolvers to use this new struct. The most likely change will be
the use of `source` instead of `resolution.target`.

## v0.4.0

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
