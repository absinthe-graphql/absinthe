# Returning Errors

> This guide could use some improvement.
>
> You can help! Please fork the [absinthe](https://github.com/absinthe-graphql/absinthe) repository, edit `guides/errors.md`, and submit a [pull request](https://github.com/absinthe-graphql/absinthe/pulls).

One or more errors for a field can be returned in a single `{:error, error_value}` tuple.

`error_value` can be:
- A simple error message string.
- A map containing `:message` key, plus any additional serializable metadata.
- A keyword list containing a `:message` key, plus any additional serializable metadata.
- A list containing multiple of any/all of these.
- Any other value compatible with `to_string/1`.

## Basic Errors

A simple error message:

``` elixir
{:error, "Something bad happened"}
```

Multiple error messages:

``` elixir
{:error, ["Something bad", "Even worse"]}
```

Single custom errors (note the required `:message` keys):

``` elixir
{:error, message: "Unknown user", code: 21}
{:error, %{message: "A database error occurred", details: format_db_error(some_value)}}
```

Three errors of mixed types:

``` elixir
{:error, ["Simple message", [message: "A keyword list error", code: 1], %{message: "A map error"}]}
```

Generic handler for interoperability with errors from other libraries:

``` elixir
{:error, :foo}
{:error, 1.0}
{:error, 2}
```

## Ecto.Changeset Errors

You may want to look at the [Absinthe ErrorPayload](https://hex.pm/packages/absinthe_error_payload) package.
