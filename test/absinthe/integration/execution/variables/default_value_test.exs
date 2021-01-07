defmodule Elixir.Absinthe.Integration.Execution.Variables.DefaultValueTest do
  use Absinthe.Case, async: true

  @times_query """
  query ($mult: Int = 6) {
    times(base: 4, multiplier: $mult)
  }
  """

  @default_value_query """
  query {
    microsecond
  }
  """

  test "query field arg default_value and resolve execution" do
    assert {:ok, %{data: %{"times" => 24}}} ==
             Absinthe.run(@times_query, Absinthe.Fixtures.TimesSchema, [])
  end

  test "query field default is evaluated only once" do
    {:ok, %{data: %{"microsecond" => first_current_microsecond}}} =
      Absinthe.run(@default_value_query, Absinthe.Fixtures.DefaultValueSchema, [])

    Process.sleep(5)

    {:ok, %{data: %{"microsecond" => second_current_microsecond}}} =
      Absinthe.run(@default_value_query, Absinthe.Fixtures.DefaultValueSchema, [])

    # If the code to grab the default_value was executed twice, this would be different
    assert first_current_microsecond == second_current_microsecond
  end
end
