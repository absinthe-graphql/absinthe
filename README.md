# Absinthe

A [GraphQL](https://facebook.github.io/graphql/) implementation for Elixir.

Please note that this is an initial release, and while functional enough to
build basic APIs (we are using it in a production system), it should be
considered experimental. (Notably, it does not yet work with Relay.)

For more information on status, see
[Specification Implementation](#Specification-Implementation), below.

## Working Features

- Basic query document execution and argument/field validation. (Note Validation
  is currently done during Execution, rather than as a separate phase. This will
  change in the next minor release.)
- Variables, including defaulting and `!` requirements.
- Full support for extending types, including scalars.
  (See [Custom Types](#Custom-Types), below.)
- Argument and input object field deprecation. (See [Deprecation](#Deprecation),
  below.)
- Errors with source line numbers. (Someday, column numbers; the Leex lexer
  doesn't support them yet.)
- An flexible adapter mechanism to translate between different naming
  conventions (eg, `snake_case` and `camelCase`) in schema vs the client.
  (See [Adapters](#Adapters), below.).

### Notably Missing

Support for:

- Fragments and fragment spreads
- Directives
- Interfaces

See [Specification Implementation](#Specification-Implementation) for more
information.

## Alternatives

You may also want to look at building from or using one of the following
alternatives.

* https://github.com/joshprice/graphql-elixir, with Plug support:
  https://github.com/joshprice/plug_graphql
* https://github.com/asonge/graphql (Parser-only as of 2015-12)

## Installation

Install from [Hex.pm](https://hex.pm/packages/absinthe):

```elixir
def deps do
  [{:absinthe, "~> 0.1.0"}]
end
```

Note: Absinthe requires Elixir 1.2.0-dev or higher.

## Learning GraphQL

For a grounding in GraphQL, I recommend you read through the following articles:

* The [GraphQL Introduction](https://facebook.github.io/react/blog/2015/05/01/graphql-introduction.html) and [GraphQL: A data query language](https://code.facebook.com/posts/1691455094417024/graphql-a-data-query-language/) posts from Facebook.
* The [Your First GraphQL Server](https://medium.com/@clayallsopp/your-first-graphql-server-3c766ab4f0a2#.m78ybemas) Medium post by Clay Allsopp. (Note this uses the [JavaScript GraphQL reference implementation](https://github.com/graphql/graphql-js).)
* Other blog posts that pop up. GraphQL is young!
* For the ambitious, the draft [GraphQL Specification](https://facebook.github.io/graphql/). Absinthe's goal is full implementation of the specification--in as an idiomatic, flexible, and comfortable way possible. The specification is linked extensively here and in the Absinthe source.

You may also be interested in how GraphQL is used by [Relay](https://facebook.github.io/relay/), a "JavaScript frameword for building data-driven React applications."

## Basic Usage

First, define a schema:

```elixir
defmodule MyApp do

  use Absinthe.Schema

  alias Absinthe.Type

  # Example data
  @items %{
    "foo" => %{id: "foo", name: "Foo"},
    "bar" => %{id: "bar", name: "Bar"}
  }

  def query do
    %Type.ObjectType{
      fields: fields(
        item: [
          type: :item
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

  @absinthe :type
  defp item do
    %Type.ObjectType{
      description: "An item",
      fields: fields(
        id: [type: Type.Scalar.id],
        name: [type: Type.Scalar.string]
      )
    }
  end

end
```

Note the `@absinthe :type` that defines the value of the `item` function as a
type (and note how `:item` is used as the `type` value for the `item` field in
the query above).

Some notes on defining types:

* By default, they will have the same atom identifier (eg, `:item`) as the
  defining function. This can be overridden, eg, `@absinthe type: :my_custom_name`
* The `name` field of the type is optional; if not provided, it will be given a
  TitleCase version of the type identifier (in this case, for example, it's
  automatically set to `"Item"`.
* You can define additional scalar types (including coercion logic); see
  [Defining Custom Types](#Defining-Custom-Types), below.

Now, you can use Absinthe to execute a query document:

```elixir
"""
{
  item(id: "") {
    name
  }
}
"""
|> Absinthe.run(MyApp.schema)

# Result
{:ok, %{data: %{"item" => %{"name" => "Foo"}}}}
```

You may want to look at the tests for more examples.

## Variables

To support variables, simply pass in a `variables` option to `run`:

```elixir
"""
query GetItem($id: ID!) {
  item(id: $id) {
    name
  }
}
"""
|> Absinthe.run(MyApp.schema, variables: %{id: "bar"})

# Result
{:ok, %{data: %{"item" => %{"name" => "Bar"}}}}
```

## Deprecation

Use the `deprecate` function on an argument definition (or input object field),
passing an optional `reason`:

```elixir
def query do
  %Type.ObjectType{
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

`resolve` functions must accept 2 arguments: a map of GraphQL arguments and a
special `%Absinthe.Execution{}` struct that provides the full execution context
(useful for advanced purposes). `resolve` functions must return a `{:ok, result}`
or `{:error, "Error to report"}` tuple.

Note: At the current time, Absinthe reports any deprecated argument or input
object field used in the `errors` entry of the response. Non null is ignored
when validating deprecated arguments and input object fields.

## Custom Types

Absinthe supports defining custom scalar types, just like the built-in types.
Here's an example of how to support a time scalar to/from ISOz format:

```elixir
@absinthe type: :iso_z
defp iso_z_type do
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

## Adapters

Absinthe supports an adapter mechanism that allows developers to define their
schema using one code convention (eg, `snake_cased` fields and arguments), but
accept query documents and return results (including names in errors) in
another (eg, `camelCase`). This is useful in allowing both client and server to
use conventions most natural to them.

Absinthe ships with two adapters:

* `Absinthe.Adapters.Passthrough`, which is a no-op adapter and makes no
  modifications. (This is the default.)
* `Absinthe.Adapters.LanguageConventions`, which expects schemas to be defined
  in `snake_case` (the standard Elixir convention), translating to/from `camelCase`
  for incoming query documents and outgoing results.

To set the adapter, you can set an application configuration value:

```elixir
config :absinthe,
  adapter: Absinthe.Adapters.LanguageConventions
```

Or, you can provide it as an option to `Absinthe.run/3`:

```elixir
Absinthe.run(query, MyApp.schema,
             adapter: Absinthe.Adapters.LanguageConventions)
```

Notably, this means you're able to switch adapters on case-by-case basis.
In a Phoenix application, this means you could even support using different
adapters for different clients.

A custom adapter module must merely implement the `Absinthe.Adapter` protocol,
in many cases with `use Absinthe.Adapter` and only overriding the desired
functions.

## Specification Implementation

Explained using the following scale:

* *Missing*: Sorry, nothing done yet!
* *Partial*: Some work done. May be used in a limited, experimental fashion, but
  some basic features may be missing.
* *Functional*: Functional for most uses, but more advanced features may be
  missing, and only loosely adheres to [parts of] the specification.
* *Complete*: Work completed. Please report any mismatches against the
  specification.

I welcome issues and pull requests; please see [CONTRIBUTING](./CONTRIBUTING).

| Section       | Implementation | Reference                                                                                 |
| ------------: | :------------- | :---------------------------------------------------------------------------------------- |
| Language      | Functional     | [GraphQL Specification, Section 2](https://facebook.github.io/graphql/#sec-Language)      |
| Type System   | Functional     | [GraphQL Specification, Section 3](https://facebook.github.io/graphql/#sec-Type-System)   |
| Introspection | Missing        | [GraphQL Specification, Section 4](https://facebook.github.io/graphql/#sec-Introspection) |
| Validation    | Partial        | [GraphQL Specification, Section 5](https://facebook.github.io/graphql/#sec-Validation)    |
| Execution     | Functional     | [GraphQL Specification, Section 6](https://facebook.github.io/graphql/#sec-Execution)     |
| Response      | Functional     | [GraphQL Specification, Section 7](https://facebook.github.io/graphql/#sec-Response)      |

For a list of specific planned features and version targets, see the
[milestone list](https://github.com/CargoSense/ex_graphql/milestones).

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
