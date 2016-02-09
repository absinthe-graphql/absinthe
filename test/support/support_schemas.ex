defmodule SupportSchemas do
  import ExUnit.Assertions

  defmacro __using__(_opts) do
    quote do: import unquote(__MODULE__)
  end

  def load_schema(name) do
    Code.require_file("test/support/schemas/#{name}.exs")
  end

  @doc """
  Assert an error occurs.

  ## Examples

  ```
  iex> assert_schema_error(TheSchema, [%{rule: Absinthe.Schema.Rule.TheRuleHere, data: :bar}])
  ```
  """
  def assert_schema_error(schema_name, patterns) do
    err = assert_raise Absinthe.Schema.Error, fn ->
      load_schema(schema_name)
    end
    patterns
    |> Enum.each(fn
      pattern ->
        assert Enum.find(err.details, fn
          detail ->
            pattern.rule == detail.rule && pattern.data == detail.data
        end)
    end)
  end

end
