# Overview

Absinthe is the GraphQL toolkit for Elixir, an implementation of the [GraphQL specification](https://spec.graphql.org) built to suit the language's capabilities and idiomatic style.

The Absinthe project consists of several complementary packages. You can find the full listing on the [absinthe-graphql](https://github.com/absinthe-graphql) GitHub organization page.

## GraphQL Basics

If you're new to GraphQL, we suggest you read up a bit on GraphQL's foundational principles before you dive into Absinthe.

Here are a few resources that might be helpful:

- The official [GraphQL](https://graphql.org/) website
- [How to GraphQL](https://www.howtographql.com/), which includes a [brief tutorial](https://www.howtographql.com/graphql-elixir/0-introduction/) using Absinthe

## Absinthe

Absinthe's functionality generally falls into two broad areas. You can read more about the details in the guides provided as part of this documentation and in the related packages/projects:

* [Defining Schemas](schemas.md). A schema:
  * defines the structure of data entities and the relationships between, as well as the available queries, mutations, and subscriptions, using an elegant collection of declarative macros
  * defines [custom scalar](custom-scalars.md) types
  * declares any [deprecated](deprecation.md) definitions
  * defines resolution functions to access data, using a flexible and extensible middleware/plugin system
* Executing Documents. A GraphQL document:
  * can be any standard GraphQL query, mutation, or subscription
  * may include reusable [variable](variables.md) definitions
  * can be analyzed for its [complexity](complexity-analysis.md) and be rejected if it's unsafe/too expensive
  * has a [context](context-and-authentication.md) that you can integrate with authentication and authorization strategies
  * can contain standard GraphQL [introspection](introspection.md) fields
  * can include multipart file uploads as GraphQL arguments (as part of the [absinthe_plug](https://hex.pm/packages/absinthe_plug) package)

## Integrations

Absinthe integrates with a number of other important projects, both on the backend and frontend, to provide a better experience for developers.

* Elixir
  * Support for HTTP APIs using [Plug and Phoenix](plug-phoenix.md) via the [absinthe_plug](https://hex.pm/packages/absinthe_plug) and [absinthe_phoenix](https://hex.pm/packages/absinthe_phoenix) packages
  * Support for [Ecto](https://hex.pm/packages/ecto) via the [dataloader](https://github.com/absinthe-graphql/dataloader) package
* JavaScript (client-side)
  * Support for [Relay](relay.md) and [Apollo Client](apollo.md)
  * Support for Absinthe's channel-based subscriptions. See [absinthe-socket](https://github.com/absinthe-graphql/absinthe-socket).

## Guides

To contribute to the guides, please submit a pull request to the [absinthe](https://github.com/absinthe-graphql/absinthe) project on GitHub.

You'll find the content under `guides/`.
