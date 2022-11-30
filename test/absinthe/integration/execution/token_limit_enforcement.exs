defmodule Elixir.Absinthe.Integration.Execution.TokenLimitEnforcement do
  use Absinthe.Case, async: true

  @query """
  {
    __typename @a @b @c @d @e
  }
  """
  test "Token limit lexer enforcement" do
    assert {:ok, %{errors: [%{message: "Token limit exceeded"}]}} ==
             Absinthe.run(@query, Absinthe.Fixtures.Things.MacroSchema, token_limit: 4)
  end
end
