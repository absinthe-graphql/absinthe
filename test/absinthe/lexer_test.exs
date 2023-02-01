defmodule Absinthe.LexerTest do
  use Absinthe.Case, async: true

  @query """
  { foo }
  """
  test "basic document" do
    assert {:ok, [{:"{", {1, 1}}, {:name, {1, 3}, 'foo'}, {:"}", {1, 7}}]} =
             Absinthe.Lexer.tokenize(@query)
  end

  @query """
  { nullName }
  """
  test "document with a name that starts with a keyword" do
    assert {:ok, [{:"{", {1, 1}}, {:name, {1, 3}, 'nullName'}, {:"}", {1, 12}}]} =
             Absinthe.Lexer.tokenize(@query)
  end

  @query ~S"""
  {
    foo
  }
  """
  test "basic document, multiple lines" do
    assert {:ok, [{:"{", {1, 1}}, {:name, {2, 3}, 'foo'}, {:"}", {3, 1}}]} =
             Absinthe.Lexer.tokenize(@query)
  end

  @query ~S"""
  {
    { foo(bar: "\\\\FOO") }
  }
  """
  test "multiple escaped slashes" do
    assert Absinthe.Lexer.tokenize(@query) ==
             {:ok,
              [
                {:"{", {1, 1}},
                {:"{", {2, 3}},
                {:name, {2, 5}, 'foo'},
                {:"(", {2, 8}},
                {:name, {2, 9}, 'bar'},
                {:":", {2, 12}},
                {:string_value, {2, 14}, ~S("\\FOO") |> String.to_charlist()},
                {:")", {2, 23}},
                {:"}", {2, 25}},
                {:"}", {3, 1}}
              ]}
  end

  @query """
  {
    foo(bar: \"""
    stuff
    \""")
  }
  """
  test "basic document, multiple lines with block string" do
    assert {:ok,
            [
              {:"{", {1, 1}},
              {:name, {2, 3}, 'foo'},
              {:"(", {2, 6}},
              {:name, {2, 7}, 'bar'},
              {:":", {2, 10}},
              {:block_string_value, {2, 12}, '"""\n  stuff\n  """'},
              {:")", {4, 6}},
              {:"}", {5, 1}}
            ]} = Absinthe.Lexer.tokenize(@query)
  end

  @query """
  # A comment with a 😕 emoji.
  \"""
  A block quote with a 👍 emoji.
  \"""
  {
    foo(bar: "A string with a 🎉 emoji.") anotherOnSameLine
  }
  """
  test "document with emojis" do
    assert {:ok,
            [
              {:block_string_value, {2, 1}, '"""\nA block quote with a 👍 emoji.\n"""'},
              {:"{", {5, 1}},
              {:name, {6, 3}, 'foo'},
              {:"(", {6, 6}},
              {:name, {6, 7}, 'bar'},
              {:":", {6, 10}},
              {:string_value, {6, 12}, '"A string with a 🎉 emoji."'},
              {:")", {6, 38}},
              {:name, {6, 40}, 'anotherOnSameLine'},
              {:"}", {7, 1}}
            ]} == Absinthe.Lexer.tokenize(@query)
  end

  @tag timeout: 3_000
  test "long query doesn't take too long" do
    # This tests the performance of long queries. Before optimization work, this
    # test took 16 seconds. After optimization it took 0.08 seconds. Setting
    # a generous ExUnit timeout ensures there has not been a performance regression
    # while hopefully preventing testing fragility.
    many_directives = String.duplicate("@abc ", 10_000)
    {:ok, _} = Absinthe.Lexer.tokenize("{ __typename #{many_directives} }")
  end
end
