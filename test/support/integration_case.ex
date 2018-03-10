defmodule Absinthe.IntegrationCase do
  @moduledoc """
  Integration tests consist of:

  - A `.graphql` file containing a GraphQL document to execute
  - A `.exs` file alongside with the same basename, containing the scenario(s) to execute

  The files are located under the directory passed as the `:root`
  option to `use Absinthe.IntegrationCase`.

  ## Setting the Schema

  The schema for a GraphQL document can be set by adding a comment at
  the beginning of the `.graphql` file, eg:

  ```
  # Schema: ColorsSchema
  ```

  The schema name provided must be under `Absinthe.Fixtures`. (For
  example, the schema set in the example above would be
  `Absinthe.Fixtures.ColorsSchema`.)

  If no schema is set, the integration test will use the
  `:default_schema` option passed to `use Absinthe.IntegrationCase`.

  ## Defining Scenarios

  You can place one or more scenarios in the `.exs` file.

  A normal scenario that checks the result of Absinthe's GraphQL
  execution is a tuple of options for `Absinthe.run` (see
  `Absinthe.run_opts`) and the expected result.

  You can omit the options if you aren't setting any. For instance,
  here's a simple result expectation:

  ```
  {:ok, %{data: %{"defaultThing" => %{"name" => "Foo"}}}}
  ```

  This could also have been written as:

  ```
  {[], {:ok, %{data: %{"defaultThing" => %{"name" => "Foo"}}}}}
  ```

  Here's another scenario example, this time making use of the options
  to set a variable:

  ```
  {[variables: %{"thingId" => "foo"}], {:ok, %{data: %{"thing" => %{"name" => "Foo"}}}}}
  ```

  If you have more than one scenario, just wrap them in a list:

  ```
  [
    {:ok, %{data: %{"defaultThing" => %{"name" => "Foo"}}}},
    {[variables: %{"thingId" => "foo"}], {:ok, %{data: %{"thing" => %{"name" => "Foo"}}}}}
  ]
  ```

  Under normal circumstances, `assert_result/2` will be used to
  compare the result of a scenario against the expectation. (Notably,
  `assert_result` ignores error `:locations`, so they do not need to
  be included in results.)

  ### Checking Exceptions

  If a tuple containing `:raise` and a module name is provided as the
  expected result for a scenario, `assert_raise/2` will be used
  instead of the normal `Absinthe.Case.assert_result/2`; this can be
  used to check scenarios with invalid resolvers, etc:

  ```
  {:raise, Absinthe.ExecutionError}
  ```

  Once again, with options for `Absinthe.run`, this would look like:

  ```
  {[variables: %{"someVar" => "value}], {:raise, Absinthe.ExecutionError}}
  ```

  ### Complex Scenario Assertions

  You can totally override the assertion logic and do your own
  execution, just using the GraphQL reading and schema setting logic,
  by defining a `run_scenario/2` function in your test module. It
  should narrowly match the test definition (so that the rest of your
  tests fall through to the normal `run_scenario/2` logic).

  ```
  def run_scenario(%{name: "path/to/integration/name"} = definition, {options, expectation} = scenario) do
    result = run(definition.graphql, definition.schema, options)
    # Do something to check the expectation against the result, etc
  end
  ```

  (For more information on the values available in `definition` above,
  see `Absinthe.IntegrationCase.Definition`.)

  In the event that you don't care about the result value, set the
  expectation to `:custom_assertion` (this is just a convention). For
  example, here's a scenario using a variable that uses a custom
  `run_scenario` match to provide its own custom assertion logic:

  ```
  {[variables: %{"name" => "something"}], :custom_assertion}
  ```
  """

  defp term_from_file!(filename) do
    elem(Code.eval_file(filename), 0)
  end

  defp definitions(root, default_schema) do
    for graphql_file <- Path.wildcard(Path.join(root, "**/*.graphql")) do
      dirname = Path.dirname(graphql_file)
      basename = Path.basename(graphql_file, ".graphql")

      integration_name =
        String.replace_leading(dirname, root, "")
        |> Path.join(basename)
        |> String.slice(1..-1)

      graphql = File.read!(graphql_file)

      raw_scenarios =
        Path.join(dirname, basename <> ".exs")
        |> term_from_file!

      __MODULE__.Definition.create(
        integration_name,
        graphql,
        default_schema,
        raw_scenarios
      )
    end
  end

  def scenario_tests(definition) do
    count = length(definition.scenarios)

    for {scenario, index} <- Enum.with_index(definition.scenarios) do
      quote do
        test unquote(definition.name) <> ", scenario #{unquote(index) + 1} of #{unquote(count)}" do
          assert_scenario(unquote(Macro.escape(definition)), unquote(Macro.escape(scenario)))
        end
      end
    end
  end

  defmacro __using__(opts) do
    root = Keyword.fetch!(opts, :root)
    default_schema = Macro.expand(Keyword.fetch!(opts, :default_schema), __ENV__)
    definitions = definitions(root, default_schema)

    [
      quote do
        use Absinthe.Case, unquote(opts)
        @before_compile unquote(__MODULE__)
      end,
      for definition <- definitions do
        scenario_tests(definition)
      end
    ]
  end

  defmacro __before_compile__(_env) do
    quote do
      def assert_scenario(definition, {options, {:raise, exception}}) when is_list(options) do
        assert_raise(exception, fn -> run(definition.graphql, definition.schema, options) end)
      end

      def assert_scenario(definition, {options, result}) when is_list(options) do
        assert_result(
          result,
          run(definition.graphql, definition.schema, options)
        )
      end
    end
  end
end
