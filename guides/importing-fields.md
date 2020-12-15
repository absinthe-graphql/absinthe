# Importing Fields

Sometimes an object type becomes too large and needs to be broken into
pieces. This is especially true of the root query, mutation, and
subscription types that are defined in the schema module itself.

Absinthe provides a mechanism,
`Absinthe.Schema.Notation.import_fields/1`, to support objects being
able to import fields from other object types.

## An Example

Let's say you're building a content management system. Your root query
type has become unwieldy over time, and your schema looks something
like this:

``` elixir
defmodule MyAppWeb.Schema do
  use Absinthe.Schema

  query do

    @desc "Get all the users, optionally filtering"
    field :users, list_of(:user) do
      # ...
    end

    @desc "Get a user using criteria"
    field :user, :user do
      # ...
    end

    # More account-related fields..

    @desc "Get all the articles, optionally filtering"
    field :articles, list_of(:article) do
      # ...
    end

    @desc "Get an article using criteria"
    field :article, :article do
      # ...
    end

    # More content-related fields...

  end

  # Other types...

end
```

This could be cleaned up to look something like this:

``` elixir
defmodule MyAppWeb.Schema do
  use Absinthe.Schema

  import_types MyAppWeb.Schema.AccountTypes
  import_types MyAppWeb.Schema.ContentTypes

  query do

    # Using :account_queries from MyAppWeb.Schema.AccountTypes
    import_fields :account_queries

    # Using :content_queries from MyAppWeb.Schema.ContentTypes
    import_fields :content_queries

  end

  # Other types...

end
```

`import_fields` here is pulling fields in from separate object types.

> Before you can import fields from another object type, make sure
> that the type in question is available to your schema. See
> the [guide](importing-types.md) on importing types for information
> on how that's done.

Here's how those object types are defined.

First, `AccountTypes`:

``` elixir
defmodule MyAppWeb.Schema.AccountTypes do
  use Absinthe.Schema.Notation

  object :account_queries do

    @desc "Get all the users, optionally filtering"
    field :users, list_of(:user) do
      # ...
    end

    @desc "Get a user using criteria"
    field :user, :user do
      # ...
    end

    # More account-related fields...

  end

  # More account-related types...

end
```

And `ContentTypes`:

``` elixir
defmodule MyAppWeb.Schema.ContentTypes do
  use Absinthe.Schema.Notation

  object :content_queries do

    @desc "Get all the articles, optionally filtering"
    field :articles, list_of(:article) do
      # ...
    end

    @desc "Get an article using criteria"
    field :article, :article do
      # ...
    end

    # More content-related fields

  end

  # More content-related types...

end
```

For more information on `import_types`, see [the guide](importing-types.md).
