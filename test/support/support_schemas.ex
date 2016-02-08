defmodule SupportSchemas do
  import ExUnit.Assertions

  defmacro __using__(_opts) do
    quote do: import unquote(__MODULE__)
  end

  def load_schema(name) do
    Code.require_file("test/support/schemas/#{name}.exs")
  end

  @doc """
  Assert problems are found.

  ## Examples

  ```
  iex> assert_schema_problems(TheSchema, [%{name: :foo, data: :bar}])
  ```
  """
  def assert_schema_problems(schema_name, patterns) do
    err = assert_raise Absinthe.Schema.Error, fn ->
      load_schema(schema_name)
    end
    patterns
    |> Enum.each(fn
      pattern ->
        assert Enum.find(err.problems, fn
          problem ->
            pattern.name == problem.name && pattern.data == problem.data
        end)
    end)
  end

end
