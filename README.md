# Absinthe

[GraphQL](https://facebook.github.io/graphql/) implementation for Elixir.

[![Build Status](https://secure.travis-ci.org/CargoSense/absinthe.svg?branch=master
"Build Status")](https://travis-ci.org/CargoSense/absinthe)

Goals:

- Complete implementation of the [GraphQL Working Draft](https://facebook.github.io/graphql), dated October 2015
- An idiomatic, readable, and comfortable API for Elixir developers
- Detailed error messages and documentation
- A focus on robustness and production-level performance

## Features

- Parser
  - All AST types
  - Fragments and type conditions
  - Line number reporting
  - ~~Column number reporting~~ (Not currently available due to Leex tokenizer constraint)
- Schema definition
  - All types (eg, Object, Input Object, Enum, Union, Interface, Scalar)
  - Circular type references
  - Support for [custom scalars](./README.md#custom-types)
  - Support for custom directives
  - Field, argument, and enum value [deprecation](./README.md#deprecation)
  - Compile-time schema validation
- [Introspection](../README.md#introspection), compatible with GraphiQL
- Query execution
  - General
  - Named fragments, inline fragments, and fragment spreads with type conditions
  - `@skip` and `@include` directives
  - [Adapter](./README.md#adapters) mechanism to support conversion between camelCase query documents
    and snake_cased schema definition.

## Related Projects

- [absinthe_plug](http://hex.pm/projects/absinthe_plug)

## Installation

Install from [Hex.pm](https://hex.pm/packages/absinthe):

```elixir
def deps do
  [{:absinthe, "~> 1.0.0-alpha1"}]
end
```

Add it to your `applications` configuration in `mix.exs`, too:

```elixir
def application do
  [applications: [:absinthe]]
end
```

Note: Absinthe requires Elixir 1.2 or higher.

## Upgrading

See [CHANGELOG](./CHANGELOG.md) for upgrade steps between versions.

## Learning GraphQL

For a grounding in GraphQL, I recommend you read through the following articles:

* The [GraphQL Introduction](https://facebook.github.io/react/blog/2015/05/01/graphql-introduction.html) and [GraphQL: A data query language](https://code.facebook.com/posts/1691455094417024/graphql-a-data-query-language/) posts from Facebook.
* The [Your First GraphQL Server](https://medium.com/@clayallsopp/your-first-graphql-server-3c766ab4f0a2#.m78ybemas) Medium post by Clay Allsopp. (Note this uses the [JavaScript GraphQL reference implementation](https://github.com/graphql/graphql-js).)
* [Learn GraphQL](https://learngraphql.com) by Kadira.
* Other blog posts that pop up. GraphQL is young!
* For the studious, the draft [GraphQL Specification](https://facebook.github.io/graphql/).

You may also be interested in how GraphQL is used by [Relay](https://facebook.github.io/relay/), a "JavaScript frameword for building data-driven React applications."

## Basic Usage

A GraphQL API starts by building a schema. Using Absinthe, schemas are normal
modules that use `Absinthe.Schema`.

For this example, we'll build a simple schema that allows users to look-up an
`item` by `id`, a required, non-null field of type `:id` (which is a built-in
type, just like `:string`, `:integer`, `:float`, and `:boolean`).

(You may want to refer to the [Absinthe API documentation](http://hexdocs.pm/absinthe/)
for more detailed information as you look this over.)

```elixir
defmodule MyApp.Schema do

  use Absinthe.Schema

  # Example data
  @items %{
    "foo" => %{id: "foo", name: "Foo"},
    "bar" => %{id: "bar", name: "Bar"}
  }

  query do
    field :item, :item do
      arg :id, non_null(:id)
      resolve fn %{id: item_id}, _ ->
        {:ok, @items[item_id]}
      end
    end
  end

end
```

Some macros and functions used here that are worth mentioning, pulled in automatically from
`Absinthe.Schema.Notation` by `use Absinthe.Schema`:

- `query` - Defines the root query object. It's like using `object` but with
   nice defaults. There is a matching `mutation` macro as well.
- `field` - Defines a field in the enclosing `object`, `input_object`, or `interface`.
- `arg` - Defines an argument in the enclosing `field` or `directive`.
- `resolve` - Sets the resolve function for the enclosing `field`.
* `non_null`: Used to add a non-null constraint to an argument. In this
  example, we are requiring an `id` to be provided to resolve the `item` field.

You'll notice we mention another type here: `:item`.

We haven't defined that yet; let's do it. In the same `MyApp.Schema` module:

```elixir
object :item do
  description "An item"
  field :id, :id
  field :name, :string
end
```

See [the documentation for Absinthe.Schema.Notation](http://hexdocs.pm/absinthe/Absinthe.Schema.Notation.html)
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

Use the `deprecate` option when defining any field, argument, or enum value.

- Provide a binary value to give a deprecation reason
- Provide `true` to just mark it as deprecated

An example:

```elixir
query do
  field :item, :item do
    arg :id, non_null(:id)
    arg :oldId, non_null(:string), deprecate: "It's old."
    resolve fn %{id: item_id}, _ ->
      {:ok, @items[item_id]}
    end
  end
end
```

Note: At the current time, Absinthe reports any deprecated argument or
deprecated input object field used in the `errors` entry of the response. Non
null constraints are ignored when validating deprecated arguments and input
object fields.

## Descriptions

Descriptions for types, directives, field, arguments, etc can be provided one of
two ways:

By passing a `:description` option to the definition:

```elixir
object :foo, description: "A Foo" do
  # ...
end
```

By using the `description` macro inside the definition:

```elixir
object :foo do
  description "A Foo"
  # ...
end
```

## Custom Types

Absinthe supports defining custom scalar types, just like the built-in types.
Here's an example of how to support a time scalar to/from ISOz format:

```elixir
scalar :iso_z, name: "ISOz" do
  description "ISOz time"
  parse &Timex.DateFormat.parse(&1, "{ISOz}")
  serialize &Timex.DateFormat.format!(&1, "{ISOz}")
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
