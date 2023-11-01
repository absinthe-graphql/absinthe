defmodule Elixir.Absinthe.Integration.Execution.TokenLimitEnforcement do
  use Absinthe.Case, async: true

  test "Token limit lexer enforcement is precise" do
    query = """
    {
      __typename @a @b @c @d @e
    }
    """

    assert {:ok, %{errors: [%{message: "Token limit exceeded"}]}} ==
             Absinthe.run(query, Absinthe.Fixtures.Things.MacroSchema, token_limit: 12)

    refute {:ok, %{errors: [%{message: "Token limit exceeded"}]}} ==
             Absinthe.run(query, Absinthe.Fixtures.Things.MacroSchema, token_limit: 13)

    query = """
    {
      test(arg1: false, arg2: ["hi \u1F600", "hello", null], arg3: 3.14) {
        results {
          id #it's a guid
          name @fakedirective

          ... on SomeType {
            some\u0046ield #should expand to someField without an extra token
          }
        }
      }
    }
    """

    # token count 33 = 8 braces + 2 parens + 2 brackets + 2 string values + 1 null + 1 float + 1 bool +
    # 3 colons + 1 ... + 1 on + 0 ignored comment + 1@ + 1 directive + 9 names

    assert {:ok, %{errors: [%{message: "Token limit exceeded"}]}} ==
             Absinthe.run(query, Absinthe.Fixtures.Things.MacroSchema, token_limit: 32)

    refute {:ok, %{errors: [%{message: "Token limit exceeded"}]}} ==
             Absinthe.run(query, Absinthe.Fixtures.Things.MacroSchema, token_limit: 33)
  end
end
