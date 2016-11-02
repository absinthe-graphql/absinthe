# Absinthe

[GraphQL](https://facebook.github.io/graphql/) implementation for Elixir.

[![Build Status](https://secure.travis-ci.org/absinthe-graphql/absinthe.svg?branch=master
"Build Status")](https://travis-ci.org/absinthe-graphql/absinthe)

Goals:

- Complete implementation of the [GraphQL Working Draft](https://facebook.github.io/graphql).
- An idiomatic, readable, and comfortable API for Elixir developers
- Extensibility based on small parts that do one thing well.
- Detailed error messages and documentation.
- A focus on robustness and production-level performance.

Please see the website at [http://absinthe-graphql.org](http://absinthe-graphql.org).

## Why Use Absinthe?

Absinthe goes far beyond GraphQL specification basics.

### Easy-to-Read, Fast-to-Run Schemas

Absinthe schemas are defined using easy-to-read macros that build and verify
their structure at compile-time, preventing runtime errors and increasing
performance.

### Pluggability

The entire query processing pipeline is configurable. Add, swap out, or remove
the parser, individual validations, or resolution logic at will, even on a
per-document basis.

### Advanced Resolution

Absinthe includes a number of advanced resolution features, to include:

- Asynchronous field resolution
- Batched field resolution (addressing N+1 query problems)
- A resolution plugin system supporting further extensibility

### Idiomatic Documents, Idiomatic Code

Write your schemas in idiomatic Elixir `snake_case` notation. Absinthe can
transparently translate to `camelCase` notation for your API clients.

Or, define your own translation scheme by writing an simple adapter.

### Frontend Support

We care about support for third-party frameworks, both on the back and
front end.

So far, we include specialized support for Phoenix and Plug on the backend,
and [Relay](https://facebook.github.io/relay/) on the frontend.

Of course we work out of the box with other frontend frameworks and GraphQL
clients, too.

### An Active Community

The project is under constant improvement by a growing list of contributors,
and your feedback is important. Please
[join us](http://absinthe-graphql.org/community/)!

## Installation

Install from [Hex.pm](https://hex.pm/packages/absinthe):

```elixir
def deps do
  [{:absinthe, "~> 1.2.0"}]
end
```

Add it to your `applications` configuration in `mix.exs`, too:

```elixir
def application do
  [applications: [:absinthe]]
end
```

Note: Absinthe requires Elixir 1.3 or higher.

## Upgrading

See [CHANGELOG](./CHANGELOG.md) for upgrade steps between versions.

## Documentation

- For the tutorial, guides, and general information about Absinthe-related
  projects, see [http://absinthe-graphql.org](http://absinthe-graphql.org).
- Links to the API documentation are available in the [project list](http://absinthe-graphql.org/projects/).

### Mix Tasks

Absinthe includes a number of useful Mix tasks for extracting schema metadata.

Run `mix help` in your project and look for tasks starting with `absinthe`.

### Roadmap

See the Roadmap on [absinthe-graphql.org](http://absinthe-graphql.org/roadmap/).

## Related Projects

See the Project List on [absinthe-graphql.org](http://absinthe-graphql.org/projects).

## License

BSD License

Copyright (c) CargoSense, Inc.

Parser derived from GraphQL Elixir, Copyright (c) Josh Price
https://github.com/graphql-elixir/graphql-elixir

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
