# Overview

Absinthe is the GraphQL toolkit for Elixir. It aims to handle authoring GraphQL schemas -- then supporting their introspection, validation, and execution according to the [GraphQL specification](https://facebook.github.io/graphql/).

The Absinthe project involves several complementary packages. You can find the full listing on the [absinthe-graphql](https://github.com/absinthe-graphql) GitHub organization page.

## GraphQL Basics

If you're new to GraphQL, we suggest you read up a bit on GraphQL's foundational principles before you dive into Absinthe.

Here are a few resources that might be helpful:

- The official [GraphQL](http://graphql.org/) website
- [How to GraphQL](https://www.howtographql.com/), which includes a [brief tutorial](https://www.howtographql.com/graphql-elixir/0-introduction/) using Absinthe

## Absinthe

Absinthe's functionality generally falls into two broad areas. You can read more about the details in the guides provided as part of this documentation and in the related packages/projects:

* [Defining Schemas](writing-schemas.html). A schema:
  * defines the structure of data entities and the relationships between, as well as the available queries, mutations, and subscriptions, using an elegant collection of declarative macros
  * defines [custom scalar](custom-scalars.html) types
  * declares any [deprecated](deprecation.html) definitions
  * defines resolution functions to access data, using a flexible and extensible middleware/plugin system
* Executing Documents. A GraphQL document:
  * can be any standard GraphQL query, mutation, or subscription
  * may include reusable [variable](variables.html) definitions
  * can be analyzed for its [complexity](complexity-analysis.html) and be rejected if it's unsafe/too expensive
  * has a [context](context-and-authentication.html) that you can integrate with authentication and authorization strategies
  * can contain standard GraphQL [introspection](introspection.html) fields
  * can include multipart file uploads as GraphQL arguments (as part of the [absinthe_plug](https://hex.pm/packages/absinthe_plug) package)

## Integrations

Absinthe integrates with a number of other important projects, both on the backend and frontend, to provide a better experience for developers.

* Elixir
  * Support for HTTP APIs using [Plug and Phoenix](plug-phoenix.html) via the [absinthe_plug](https://hex.pm/packages/absinthe_plug) and [absinthe_phoenix](https://hex.pm/packages/absinthe_phoenix) packages
  * Support for [Ecto](ecto-best-practices.html) via the [absinthe_ecto](https://hex.pm/packages/absinthe_ecto) package
* JavaScript (client-side)
  * Support for specific [Relay Framework](relay.html) patterns
  * Support for Absinthe's channel-based subscriptions. This in an evolving area, see [absinthe_phoenix](https://github.com/absinthe-graphql/absinthe_phoenix) for links to related projects.

## Guides

To contribute to the guides, please submit a pull request to the [absinthe](https://github.com/absinthe-graphql/absinthe) project on GitHub.

You'll find the content under `guides/`.
