# ExGraphQL

A [GraphQL](https://facebook.github.io/graphql/) implementation in Elixir.

## Alternatives

* https://github.com/joshprice/graphql-elixir
* https://github.com/asonge/graphql (Parser-only as of 2015-12)

## Installation

Install from [Hex.pm](https://hex.pm/packages/ex_graphql):

```elixir
def deps do
  [{:ex_graphql, "~> 0.1.0"}]
end
```

Note: ExGraphQL requires Elixir 1.2.0-dev or higher.

## Learning GraphQL

For a grounding in GraphQL, I recommend you read through the following articles:

* The [GraphQL Introduction](https://facebook.github.io/react/blog/2015/05/01/graphql-introduction.html) and [GraphQL: A data query language](https://code.facebook.com/posts/1691455094417024/graphql-a-data-query-language/) posts from Facebook.
* The [Your First GraphQL Server](https://medium.com/@clayallsopp/your-first-graphql-server-3c766ab4f0a2#.m78ybemas) Medium post by Clay Allsopp. (Note this uses the [JavaScript GraphQL reference implementation](https://github.com/graphql/graphql-js).)
* Other blog posts that pop up. GraphQL is young!
* For the ambitious, the draft [GraphQL Specification](https://facebook.github.io/graphql/). ExGraphQL's goal is full implementation of the specification--in as an idiomatic, flexible, and comfortable way possible. The specification is linked extensively here and in the ExGraphQL source.

You may also be interested in how GraphQL is used by [Relay](https://facebook.github.io/relay/), a "JavaScript frameword for building data-driven React applications."

## Specification Implementation

The following table uses this scale:

* *Missing*: Sorry, nothing done yet!
* *Partial*: Some work done. May be used in a limited, experimental fashion, but some basic features may be missing.
* *Operational*: Mostly done. Should be functional for most uses, but more advanced features may be missing.
* *Complete*: Work completed. Please report any mismatches against the specification.

I welcome issues and pull requests; please see [CONTRIBUTING](./CONTRIBUTING) for details on how to submit them in as helpfully as possible.

| Section     | Implementation | Reference |
| ------:     | :---- | :---- |
| Language    | Complete | [GraphQL Specification, Section 2](https://facebook.github.io/graphql/#sec-Language) |
| Type System | Operational | [GraphQL Specification, Section 3](https://facebook.github.io/graphql/#sec-Type-System) |
| Introspection | Missing | [GraphQL Specification, Section 4](https://facebook.github.io/graphql/#sec-Introspection) |
| Validation  | Partial | [GraphQL Specification, Section 5](https://facebook.github.io/graphql/#sec-Validation) |
| Execution   | Operational | [GraphQL Specification, Section 6](https://facebook.github.io/graphql/#sec-Execution). |
| Response    | Complete | [GraphQL Specification, Section 7](https://facebook.github.io/graphql/#sec-Response) |

See [STATUS](./STATUS.html) for more detailed information.

## Roadmap

See [ROADMAP](./ROADMAP.html).

## License

TODO
