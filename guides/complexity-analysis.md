# Complexity Analysis

A misbehaving client might send a very complex GraphQL query that would require
considerable resources to handle. In order to protect against this scenario, the
complexity of a query can be estimated before it is resolved and limited to a
specified maximum.

For example, to enable complexity analysis and limit the complexity to a value
of `50` -- if we were using `Absinthe.run/3` directly -- we would do this:

```elixir
Absinthe.run(doc, MyAppWeb.Schema, analyze_complexity: true, max_complexity: 50)
```

That would translate to the following configuration when using
[absinthe_plug](https://hex.pm/packages/absinthe_plug) (>= v1.2.3):

```elixir
plug Absinthe.Plug,
  schema: MyAppWeb.Schema,
  analyze_complexity: true,
  max_complexity: 50
```

The maximum value, `50`, is compared to complexity values calculated for each request.

## Complexity Analysis

Here's how the complexity value is calculated:

By default each field in a query will increase the complexity by 1. However, it
can be useful to customize how the complexity value for a field is calculated. This is done in your schema using the
`complexity/1` macro, which can accept a function or an explicit integer value.

As an example, when a field is a list, the complexity is often correlated to the
size of the list. To prevent large selections, a field can use a limit argument
with a suitable default (think, for instance, of page sizes during pagination),
and complexity can be calculated keeping that in mind. Here is a schema that
supports analyzing (and limiting) complexity using that approach:

```elixir
defmodule MyAppWeb.Schema do

  use Absinthe.Schema

  query do
    field :people, list_of(:person) do
      arg :limit, :integer, default_value: 10
      complexity fn %{limit: limit}, child_complexity ->
        # set complexity based on maximum number of items in the list and
        # complexity of a child.
        limit * child_complexity
      end
    end
  end

  object :person do
    field :name, :string
    field :age, :integer
  end

end
```

For a field, the first argument to the function you supply to `complexity/1` is the user arguments
-- just as a field's resolver can use user arguments to resolve its value, the complexity
function that you provide can use the same arguments to calculate the field's complexity.

The second argument passed to your complexity function is the sum of all the complexity scores
of all the fields nested below the current field.

(If a complexity function accepts three arguments, the third will be an
`%Absinthe.Resolution{}` struct, just as with resolvers.)

If the value of a document's `:limit` argument was `10` and both `name` and `age` were queried for,
the complexity of the `:people` field would be calculated as `20`:

* `10`, the value of `:limit`
* times `2`, the sum of the complexity of the fields requested on the `:person`

A field's complexity will default to `1` if it's not set explicitly.

So this would be okay:

```graphql
{
  people(limit: 10) {
    name
  }
}
```

But this, at a complexity of `60`, wouldn't:

```graphql
{
  people(limit: 30) {
    name
  }
}
```

### Complexity limiting

If a document's calculated complexity exceeds the configured limit, resolution
will be skipped and an error will be returned in the result detailing the
calculated and maximum complexities.

Example Error:

```json
{
	"errors": [
		{
			"locations": [
				{
					"column": 5,
					"line": 188
				}
			],
			"message": "Field transactions is too complex: complexity is 2400 and maximum is 250"
		}
	]
}
```

### Complexity Nuance

If you set a static complexity on a field like so:

```elixir
defmodule MyAppWeb.Schema do

  use Absinthe.Schema

  query do
    field :people, list_of(:person) do
      arg :limit, :integer, default_value: 10
    end
  end

  object :person do
    field :name, :string
    field :age, :integer
    field :address, non_null(:string) do
      complexity 10
      resolve Query.resolve_address()
    end
  end

  object :address do
    field :street, :string
    field :geolocation, :string do
      complexity 10
      resolve Query.resolve_geolocation()
    end
  end
end
```

The static complexity will prevent any child complexity calculations from happening.
So if you can query `geolocation` on `address` of complexity 10 on a `person`
you may think that address `10` + `geolocation` 10 should be complexity
of 20 but it will be 10 because the static complexity set on `address` overrides
any child complexity.

To address this, ensure all fields up the object chain have child complexity functions

```elixir
defmodule MyAppWeb.Schema do

  use Absinthe.Schema

  query do
    field :people, list_of(:person) do
      arg :limit, :integer, default_value: 10
    end
  end

  object :person do
    field :name, :string
    field :age, :integer
    field :address, non_null(:string) do
      complexity fn _args_map, child_complexity ->
        10 + child_complexity
      end
      resolve Query.resolve_address()
    end
  end

  object :address do
    field :street, :string
    field :geolocation, :string do
      complexity fn _args_map, child_complexity ->
        10 + child_complexity
      end
      resolve Query.resolve_geolocation()
    end
  end
end
```

This new schema will result in a complexity of 20 if you query
`person -> address -> geolocation`.

Prefer child_complexity functions over static complexity to avoid
unexpected complexity calculations.
