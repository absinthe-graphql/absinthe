# Changelog

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
object :car do
  description "A car"

  field :picture_url, :string do
    description "Photo URL"

    arg :size, non_null(:string)
    description "The size of the photo"

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
