defmodule SupportSchemas do
  import ExUnit.Assertions

  defmacro __using__(_opts) do
    quote do: import unquote(__MODULE__)
  end

  def load_schema(name) do
    Code.require_file("test/support/schemas/#{name}.exs")
  end

  @doc """
  Assert a schema error occurs.

  ## Examples

  ```
  iex> assert_schema_error("schema-name", [%{rule: Absinthe.Schema.Rule.TheRuleHere, data: :bar}])
  ```
  """
  def assert_schema_error(schema_name, patterns) do
    err = assert_raise Absinthe.Schema.Error, fn ->
      load_schema(schema_name)
    end
    patterns
    |> Enum.filter(fn
      pattern ->
        assert Enum.find(err.details, fn
          detail ->
            pattern.rule == detail.rule && pattern.data == detail.data
        end), "Could not find error detail pattern #{inspect pattern} in #{inspect err.details}"
    end)
    assert length(patterns) == length(err.details)
  end
  def assert_notation_error(name) do
    assert_raise(Absinthe.Schema.Notation.Error, fn ->
      load_schema(name)
    end)
  end

end
