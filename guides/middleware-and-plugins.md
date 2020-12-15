# Writing Middleware and Plugins

Middleware enables custom resolution behaviour on a field. You can use them to share common logic that needs to happen before or after resolving fields. Things like authentication and error handling.

## Create a Middleware
In order to create a `Middleware` you need a module that implements `Absinthe.Middleware` behaviour . Your module needs to have a `call/2` method which receives an `%Absinthe.Resolution{}` struct and some options as its parameters, and then returns a possibly altered resolution struct.

Here is an example of a middleware that handle `Ecto.Changeset` errors and makes sure we properly add error message to the `errors` in the response.

```elixir
defmodule MyApp.Middlewares.HandleChangesetErrors do
  @behaviour Absinthe.Middleware
  def call(resolution, _) do
    %{resolution |
      errors: Enum.flat_map(resolution.errors, &handle_error/1)
    }
  end

  defp handle_error(%Ecto.Changeset{} = changeset) do
    changeset
      |> Ecto.Changeset.traverse_errors(fn {err, _opts} -> err end)
      |> Enum.map(fn({k,v}) -> "#{k}: #{v}" end)
  end
  defp handle_error(error), do: [error]
end
```

The resolution struct has all kinds of useful values inside of it. You can access the Absinthe context, the root value, information about the current field's AST, and more. For more information on how the current user ends up in the context please see our full [authentication guide](context-and-authentication.md).

## Using Middlewares
Middleware can be placed on a field in few different ways:

### 1. Using the `Absinthe.Schema.Notation.middleware/2` macro used inside a field definition
This option is good when you want to add your middleware on few specific fields. You can use `middleware` to add multiple Middlewares before or after `resolve`. In this example `MyApp.Web.Authentication` would run before resolution, and `HandleError` would run after.

```elixir
field :hello, :string do
  middleware MyApp.Web.Authentication
  resolve &get_the_string/2
  middleware HandleError, :foo
end
```

### 2. Using the `middleware/3` callback in your schema.
This option is good if you want to add your middleware on all or a group of fields based on the type of query. `middleware/3` is a function callback on a schema. When you `use Absinthe.Schema` a default implementation of this function is placed in your schema. It is passed the existing middleware for a field, the field itself, and the object that the field is a part of.
You can override this callback to add your Middleware in the list of existing middlewares. In this example we add our `HandleChangesetError` Middleware only to mutations.

```elixir
# add this to your schema module

# if it's a field for the mutation object, add this middleware to the end
def middleware(middleware, _field, %{identifier: :mutation}) do
  middleware ++ [MyApp.Middlewares.HandleChangesetErrors]
end
# if it's any other object keep things as is
def middleware(middleware, _field, _object), do: middleware
```

### 3. Returning a `{:middleware, middleware_spec, config}` tuple from a resolution function.
You can update your resolution function to return `{:middleware, MyApp.Middlewares.HandleChangesetErrors, config}`, note that in this case the middleware can only be applied after the resolution.
