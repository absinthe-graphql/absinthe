# Absinthe

[GraphQL](https://facebook.github.io/graphql/) implementation for Elixir.

[![Hex pm](http://img.shields.io/hexpm/v/absinthe.svg?style=flat)](https://hex.pm/packages/absinthe)[![Build Status](https://secure.travis-ci.org/absinthe-graphql/absinthe.svg?branch=master
"Build Status")](https://travis-ci.org/absinthe-graphql/absinthe)[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

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

### Safety

- Complexity analysis and configurable limiting
- Support for precompiled documents/preventing custom documents

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

Please remember that all interactions in our official spaces follow our [Code of
Conduct](./CODE_OF_CONDUCT.md).

## Installation

Install from [Hex.pm](https://hex.pm/packages/absinthe):

```elixir
def deps do
  [{:absinthe, "~> 1.3.1"}]
end
```

Add it to your `applications` configuration in `mix.exs`, too:

```elixir
def application do
  [applications: [:absinthe]]
end
```

Note: Absinthe requires Elixir 1.4 or higher.

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

See [LICENSE.md](./LICENSE.md).
