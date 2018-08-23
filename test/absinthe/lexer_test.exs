defmodule Absinthe.LexerTest do
  use ExUnit.Case, async: true

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
end
