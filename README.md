# Absinthe

A [GraphQL](https://facebook.github.io/graphql/) implementation for Elixir.

[![Build Status](https://secure.travis-ci.org/CargoSense/absinthe.svg?branch=master
"Build Status")](https://travis-ci.org/CargoSense/absinthe)

Please note that this is a young project and that portions of the specification
aren't fully implemented yet.

That said, we are using Absinthe in production, and we'd love your input
and support to make it better.

For more information on status, see [Specification Implementation](./README.md#specification-implementation), below.

## Goal

Absinthe's goal is full implementation of the specification--in as
idiomatic, flexible, and comfortable way possible.

### Working Features

- A clean, conventional, module-based approach to building schemas.
- Full support for extending types, including scalars.
  (See [Custom Types](./README.md#custom-types), below.)
- Argument, input object field, and enum value deprecation.
  (See [Deprecation](./README.md#deprecation),
  below.)
- Basic query document execution and argument/field validation. (Note Validation
  is currently done during Execution, rather than as a separate phase. This will be
  [changed soon](https://github.com/CargoSense/absinthe/issues/17), even if this
  doesn't appreciably affect the functionality of APIs written with Absinthe.)
- Support for Plug, via [absinthe_plug](http://hex.pm/projects/absinthe_plug).
- Variables, including defaulting and `!` requirements.
- Interface validation/resolution.
- Named fragments and fragment spreads
- [Introspection](../README.md#introspection) (of everything but directives,
  currently).
- Errors with source line numbers. (Someday, column numbers; the Leex lexer
  doesn't support them yet.)
- An flexible adapter mechanism to translate between different naming
  conventions (eg, `snake_case` and `camelCase`) in schema vs the client.
  (See [Adapters](./README.md#adapters), below.)

### Notably Missing

Support for:

- Inline fragments
- Directives

### Alternatives

You may also want to look at building from or using one of the following
alternatives.

* https://github.com/joshprice/graphql-elixir, also with Plug support:
  https://github.com/joshprice/plug_graphql
* https://github.com/asonge/graphql (Parser-only as of 2015-12)

## Installation

Install from [Hex.pm](https://hex.pm/packages/absinthe):

```elixir
def deps do
  [{:absinthe, "~> 0.4.0"}]
end
```

Add it to your `applications` configuration in `mix.exs`, too:

```elixir
def application do
  [applications: [:absinthe]]
end
```

Note: Absinthe requires Elixir 1.2-dev or higher.

## Learning GraphQL

For a grounding in GraphQL, I recommend you read through the following articles:

* The [GraphQL Introduction](https://facebook.github.io/react/blog/2015/05/01/graphql-introduction.html) and [GraphQL: A data query language](https://code.facebook.com/posts/1691455094417024/graphql-a-data-query-language/) posts from Facebook.
* The [Your First GraphQL Server](https://medium.com/@clayallsopp/your-first-graphql-server-3c766ab4f0a2#.m78ybemas) Medium post by Clay Allsopp. (Note this uses the [JavaScript GraphQL reference implementation](https://github.com/graphql/graphql-js).)
* Other blog posts that pop up. GraphQL is young!
* For the ambitious, the draft [GraphQL Specification](https://facebook.github.io/graphql/).

You may also be interested in how GraphQL is used by [Relay](https://facebook.github.io/relay/), a "JavaScript frameword for building data-driven React applications."

## Basic Usage

A GraphQL API starts by building a schema. Using Absinthe, schemas are normal
modules that use `Absinthe.Schema` and adhere to its behavior (ie, define at
least `query`).

For this example, we'll build a simple schema that allows users to look-up an
`item` by `id`, a required, non-null field of type `:id` (which is a built-in
type, just like `:string`, `:integer`, `:float`, and `:boolean`).

(You may want to refer to the [Absinthe API documentation](http://hexdocs.pm/absinthe/0.1.0/)
for more detailed information as you look this over.)

```elixir
defmodule MyApp.Schema do

  use Absinthe.Schema

  alias Absinthe.Type

  # Example data
  @items %{
    "foo" => %{id: "foo", name: "Foo"},
    "bar" => %{id: "bar", name: "Bar"}
  }

  def query do
    %Type.Object{
      fields: fields(
        item: [
          type: :item,
          args: args(
            id: [type: non_null(:id)]
          ),
          resolve: fn %{id: item_id}, _ ->
            {:ok, @items[item_id]}
          end
        ]
      )
    }
  end

end
```

Some functions used here that are worth mentioning, pulled in automatically from
`Absinthe.Type.Definitions` by `use Absinthe.Schema`:

* `args()` and `fields()` are utility functions that reduce clutter in your
  schema (by building maps of nicely-named `%Type.Argument{}` and
  `%Type.Field{}` structs, respectively, for you).
* `non_null()`: Used to add a non-null constraint to an argument. In this
  example, we are requiring an `id` to be provided to resolve the `item` field.

You'll notice we mention another type here: `:item`.

We haven't defined that yet; let's do it. In the same `MyApp.Schema` module:

```elixir
@absinthe :type
def item do
  %Type.Object{
    description: "An item",
    fields: fields(
      id: [type: :id],
      name: [type: :string]
    )
  }
end
```

Some notes on defining types:

* By default, they will have the same atom identifier (eg, `:item`) as the
  defining function. This can be overridden, eg, `@absinthe type: :my_custom_name`
* The `name` field of the `Type.Object` struct is optional; if not provided,
  it will be automatically set to a TitleCase version of the type identifier
  (in this case, it's set to `"Item"`).
* You can define additional scalar types (including coercion logic); see
  [Custom Types](./README.md#custom-types), below.

See [the documentation for Absinthe.Type.Definitions](http://hexdocs.pm/absinthe/Absinthe.Type.Definitions.html)
for more information.

Now, you can use Absinthe to execute a query document. Keep in mind that for
HTTP, you'll probably want to use
[absinthe_plug](http://hex.pm/projects/absinthe_plug) instead of executing
GraphQL query documents yourself. Absinthe doesn't know or care about HTTP,
but absinthe_plug does -- and handles the vagaries of interacting with HTTP
GraphQL clients so you don't have to.

If you _were_ executing query documents yourself (lets assume for a local tool),
it would go something like this:

```elixir
"""
{
  item(id: "foo") {
    name
  }
}
"""
|> Absinthe.run(MyApp.Schema)

# Result
{:ok, %{data: %{"item" => %{"name" => "Foo"}}}}
```

Query documents also support variables:

## Variables

To support variables, simply define them for your query document [as the specification expects](https://facebook.github.io/graphql/#sec-Language.Query-Document.Variables),
and pass in a `variables` option (eg, [absinthe_plug](http://hex.pm/projects/absinthe_plug) handles providing these directly from query parameters or the POST body) to `run`:

```elixir
"""
query GetItem($id: ID!) {
  item(id: $id) {
    name
  }
}
"""
|> Absinthe.run(MyApp.Schema, variables: %{id: "bar"})

# Result
{:ok, %{data: %{"item" => %{"name" => "Bar"}}}}
```

## Deprecation

Use the `deprecate` function on an argument definition (or input object field),
passing an optional `reason`:

```elixir
def query do
  %Type.Object{
    name: "RootQuery",
    fields: fields(
      item: [
        type: :item
        args: args(
          id: [type: non_null(:id)],
          oldId: deprecate([type: non_null(:string)],
                           reason: "It's old.")
        ),
        resolve: fn %{id: item_id}, _ ->
          {:ok, @items[item_id]}
        end
      ]
    )
  }
end
```

`resolve` functions must accept 2 arguments: a map of arguments and a
special `%Absinthe.Execution{}` struct that provides the full execution context
(useful for advanced purposes). `resolve` functions must return a `{:ok, result}`
or `{:error, "Error to report"}` tuple.

Note: At the current time, Absinthe reports any deprecated argument or
deprecated input object field used in the `errors` entry of the response. Non
null constraints are ignored when validating deprecated arguments and input
object fields.

## Custom Types

Absinthe supports defining custom scalar types, just like the built-in types.
Here's an example of how to support a time scalar to/from ISOz format:

```elixir
@absinthe type: :iso_z
def iso_z_type do
  %Type.Scalar{
    name: "ISOz",
    description: "ISOz time",
    parse: &Timex.DateFormat.parse(&1, "{ISOz}"),
    serialize: &Timex.DateFormat.format!(&1, "{ISOz}")
  }
end
```

Now `:iso_z` can be used in your schema and variables can use
`ISOz` in query documents.

## Introspection

You can introspect your schema using `__schema`, `__type`, and `__typename`,
as [described in the specification](https://facebook.github.io/graphql/#sec-Introspection).

### Examples

Seeing the names of the types in the schema:

```elixir
"""
{
  __schema {
    types {
      name
    }
  }
}
"""
|> Absinthe.run(MyApp.Schema)
{:ok,
  %{data: %{
    "__schema" => %{
      "types" => [
        %{"name" => "Boolean"},
        %{"name" => "Float"},
        %{"name" => "ID"},
        %{"name" => "Int"},
        %{"name" => "String"},
        ...
      ]
    }
  }}
}
```

Getting the name of the queried type:

```elixir
"""
{
  profile {
    name
    __typename
  }
}
"""
|> Absinthe.run(MyApp.Schema)
{:ok,
  %{data: %{
    "profile" => %{
      "name" => "Joe",
      "__typename" => "Person"
    }
  }}
}
```

Getting the name of the fields for a named type:

```elixir
"""
{
  __type(name: "Person") {
    fields {
      name
      type {
        kind
        name
      }
    }
  }
}
"""
|> Absinthe.run(MyApp.Schema)
{:ok,
  %{data: %{
    "__type" => %{
      "fields" => [
        %{
          "name" => "name",
          "type" => %{"kind" => "SCALAR", "name" => "String"}
        },
        %{
          "name" => "age",
          "type" => %{"kind" => "SCALAR", "name" => "Int"}
        },
      ]
    }
  }}
}
```

(Note that you may have to nest several depths of `type`/`ofType`, as
type information includes any wrapping layers of [List](https://facebook.github.io/graphql/#sec-List)
and/or [NonNull](https://facebook.github.io/graphql/#sec-Non-null).)

### Limitations

- Directives cannot currently be introspected.

## Adapters

Absinthe supports an adapter mechanism that allows developers to define their
schema using one code convention (eg, `snake_cased` fields and arguments), but
accept query documents and return results (including names in errors) in
another (eg, `camelCase`). This is useful in allowing both client and server to
use conventions most natural to them.

Absinthe ships with two adapters:

* `Absinthe.Adapter.LanguageConventions`, which expects schemas to be defined
  in `snake_case` (the standard Elixir convention), translating to/from `camelCase`
  for incoming query documents and outgoing results. (This is the default as of v0.3.)
* `Absinthe.Adapter.Passthrough`, which is a no-op adapter and makes no
  modifications.

To set the adapter, you can set an application configuration value:

```elixir
config :absinthe,
  adapter: Absinthe.Adapter.TheAdapterName
```

Or, you can provide it as an option to `Absinthe.run/3`:

```elixir
Absinthe.run(query, MyApp.Schema,
             adapter: Absinthe.Adapter.TheAdapterName)
```

Notably, this means you're able to switch adapters on case-by-case basis.
In a Phoenix application, this means you could even support using different
adapters for different clients.

A custom adapter module must merely implement the `Absinthe.Adapter` protocol,
in many cases with `use Absinthe.Adapter` and only overriding the desired
functions.

Note that types that are defined external to your application (including
the introspection types) may not be compatible if you're using a different
adapter.

## Specification Implementation

Absinthe is currently targeting the [GraphQL Working Draft](https://facebook.github.io/graphql), dated October 2015.

Here's the basic status, using the following scale:

* *Missing*: Sorry, nothing done yet!
* *Partial*: Some work done. May be used in a limited, experimental fashion, but
  some basic features may be missing.
* *Functional*: Functional for most uses, but more advanced features may be
  missing, and only loosely adheres to [parts of] the specification.
* *Complete*: Work completed. Please report any mismatches against the
  specification.

| Section       | Implementation | Reference                                                                                 |
| ------------: | :------------- | :---------------------------------------------------------------------------------------- |
| Language      | Functional     | [GraphQL Specification, Section 2](https://facebook.github.io/graphql/#sec-Language)      |
| Type System   | Functional     | [GraphQL Specification, Section 3](https://facebook.github.io/graphql/#sec-Type-System)   |
| Introspection | Functional     | [GraphQL Specification, Section 4](https://facebook.github.io/graphql/#sec-Introspection) |
| Validation    | Partial        | [GraphQL Specification, Section 5](https://facebook.github.io/graphql/#sec-Validation)    |
| Execution     | Functional     | [GraphQL Specification, Section 6](https://facebook.github.io/graphql/#sec-Execution)     |
| Response      | Functional     | [GraphQL Specification, Section 7](https://facebook.github.io/graphql/#sec-Response)      |

### Roadmap & Contributions

For a list of specific planned features and version targets, see the
[milestone list](https://github.com/CargoSense/absinthe/milestones).

We welcome issues and pull requests; please see CONTRIBUTING.

## License

BSD License

Copyright (c) CargoSense, Inc.

Parser derived from GraphQL Elixir, Copyright (c) Josh Price
https://github.com/joshprice/graphql-elixir

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

 * Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

 * Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

 * Neither the name Facebook nor the names of its contributors may be used to
   endorse or promote products derived from this software without specific
   prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
