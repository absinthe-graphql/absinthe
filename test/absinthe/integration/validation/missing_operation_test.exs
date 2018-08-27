defmodule Elixir.Absinthe.Integration.Validation.MissingOperationTest do
  use ExUnit.Case, async: true

  @query """
  mutation { foo }
  """

  test "scenario #1" do
    assert {:ok, %{errors: [%{message: "Operation \"mutation\" not supported"}]}} == Absinthe.run(@query, Absinthe.Fixtures.OnlyQuerySchema, [])
  end
end
