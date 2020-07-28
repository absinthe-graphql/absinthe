defmodule Elixir.Absinthe.Integration.Execution.InputObjectTest do
  use Absinthe.Case, async: true

  import ExUnit.CaptureLog

  @query """
  mutation {
    updateThing(id: "foo", thing: {value: 100}) {
      name
      value
    }
  }
  """

  test "scenario #1" do
    assert {:ok, %{data: %{"updateThing" => %{"name" => "Foo", "value" => 100}}}} ==
             Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema, [])
  end

  @query """
  mutation ($input: Boolean) {
    updateThing(id: "foo", thing: $input) {
      name
      value
    }
  }
  """

  test "logs a warning if an invalid type is passed" do
    fun = fn ->
      Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema, variables: %{"input" => true})
    end

    assert capture_log([level: :warn], fun) =~
             "WARNING! The field type and schema types are different"
  end
end
