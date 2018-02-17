defmodule Absinthe.Test do
  @doc """
  Run the introspection query on a schema.

  In your `test_helper.exs` file add
  ```
  Absinthe.Test.prime(MyApp.Schema)
  ```

  ## Explanation

  In the test environment mix loads code lazily, which means that it isn't until
  the first GraphQL query in your test suite runs that Absinthe's code base is
  actually loaded. Absinthe is a lot of code, and so this can take several
  milliseconds. This can be a problem for tests using message passing that expect
  messages to happen within a certain amount of time.

  By running the introspection query on your schema this function will cause mix
  to load the majority of the Absinthe code base.
  """
  def prime(schema_name) do
    {:ok, %{data: _}} = Absinthe.Schema.introspect(schema_name)
    :ok
  end
end
