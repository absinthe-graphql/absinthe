defmodule Absinthe.UnicodeTest do
  @moduledoc """
  Tests for GraphQL September 2025 Full Unicode Support (RFCs #805, #1040, #1053, #1142).

  This test module covers:
  - Basic Unicode characters in strings
  - BMP escape sequences (\\uXXXX)
  - Extended/variable-width escape sequences (\\u{XXXXXX})
  - Surrogate pair handling for legacy compatibility
  - Emoji and supplementary plane characters
  - Unicode validation (rejection of invalid escapes)
  - Block strings with Unicode
  """

  use Absinthe.Case, async: true

  alias Absinthe.Lexer

  describe "basic Unicode in strings" do
    test "parses ASCII characters" do
      assert {:ok, [{:string_value, {1, 1}, ~c"\"hello\""}]} =
               Lexer.tokenize(~s("hello"))
    end

    test "parses Latin-1 supplement characters" do
      # e with acute accent (actual character, not escaped)
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~s("cafe"))

      assert to_string(value) == "\"cafe\""
    end

    test "parses Cyrillic characters" do
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~s("Hello"))

      assert to_string(value) == ~s("Hello")
    end

    test "parses Chinese characters" do
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~s("Hello"))

      assert to_string(value) == ~s("Hello")
    end

    test "parses Japanese characters" do
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~s(""))

      assert to_string(value) == ~s("")
    end

    test "parses Arabic characters" do
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~s(""))

      assert to_string(value) == ~s("")
    end

    test "parses mixed Unicode scripts" do
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~s("Hello World"))

      assert to_string(value) == ~s("Hello World")
    end
  end

  describe "BMP escape sequences (\\uXXXX)" do
    test "parses basic ASCII escape" do
      # \u0041 = 'A'
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~S("\u0041"))

      assert to_string(value) == "\"A\""
    end

    test "parses Latin-1 escape" do
      # \u00F3 = 'o' with acute accent
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~S("\u00F3"))

      assert to_string(value) == "\"\u00F3\""
    end

    test "parses lowercase hex digits" do
      # \u00f3 = 'o' with acute accent (lowercase)
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~S("\u00f3"))

      assert to_string(value) == "\"\u00F3\""
    end

    test "parses mixed case hex digits" do
      # \u00Ab = same as \u00AB
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~S("\u00Ab"))

      assert to_string(value) == "\"\u00AB\""
    end

    test "parses Cyrillic escape" do
      # \u0414 = Cyrillic capital letter De
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~S("\u0414"))

      assert to_string(value) == "\"\u0414\""
    end

    test "parses BMP character at end of range" do
      # \uFFFF = last BMP character
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~S("\uFFFF"))

      assert to_string(value) == "\"\uFFFF\""
    end

    test "parses null character" do
      # \u0000 = null character
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~S("\u0000"))

      assert to_string(value) == "\"\u0000\""
    end

    test "parses multiple escape sequences" do
      # \u0041\u0042\u0043 = "ABC"
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~S("\u0041\u0042\u0043"))

      assert to_string(value) == "\"ABC\""
    end

    test "parses escape mixed with plain text" do
      # "Hello \u0041 World"
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~S("Hello \u0041 World"))

      assert to_string(value) == "\"Hello A World\""
    end
  end

  describe "extended Unicode escape sequences (\\u{XXXXXX})" do
    test "parses single digit hex" do
      # \u{41} = 'A'
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~S("\u{41}"))

      assert to_string(value) == "\"A\""
    end

    test "parses two digit hex" do
      # \u{F3} = 'o' with acute accent
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~S("\u{F3}"))

      assert to_string(value) == "\"\u00F3\""
    end

    test "parses four digit hex (equivalent to fixed-width)" do
      # \u{0041} = 'A'
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~S("\u{0041}"))

      assert to_string(value) == "\"A\""
    end

    test "parses five digit hex (supplementary plane)" do
      # \u{1F600} = grinning face emoji
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~S("\u{1F600}"))

      assert to_string(value) == "\"\u{1F600}\""
    end

    test "parses six digit hex (max Unicode)" do
      # \u{10FFFF} = last valid Unicode code point
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~S("\u{10FFFF}"))

      assert to_string(value) == "\"\u{10FFFF}\""
    end

    test "parses lowercase hex in variable-width" do
      # \u{1f600} = grinning face emoji (lowercase)
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~S("\u{1f600}"))

      assert to_string(value) == "\"\u{1F600}\""
    end

    test "parses mixed case hex in variable-width" do
      # \u{1F6aB} = prohibited sign emoji
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~S("\u{1F6aB}"))

      assert to_string(value) == "\"\u{1F6AB}\""
    end

    test "parses poop emoji" do
      # \u{1F4A9} = pile of poo
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~S("\u{1F4A9}"))

      assert to_string(value) == "\"\u{1F4A9}\""
    end

    test "parses musical symbol" do
      # \u{1D11E} = musical symbol G clef
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~S("\u{1D11E}"))

      assert to_string(value) == "\"\u{1D11E}\""
    end
  end

  describe "surrogate pair handling (legacy compatibility)" do
    test "parses surrogate pair for poop emoji" do
      # \uD83D\uDCA9 = pile of poo (U+1F4A9) via surrogate pair
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~S("\uD83D\uDCA9"))

      # Should produce the same result as \u{1F4A9}
      assert to_string(value) == "\"\u{1F4A9}\""
    end

    test "parses surrogate pair for grinning face" do
      # \uD83D\uDE00 = grinning face (U+1F600) via surrogate pair
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~S("\uD83D\uDE00"))

      assert to_string(value) == "\"\u{1F600}\""
    end

    test "parses surrogate pair for G clef" do
      # \uD834\uDD1E = G clef (U+1D11E) via surrogate pair
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~S("\uD834\uDD1E"))

      assert to_string(value) == "\"\u{1D11E}\""
    end

    test "surrogate pair and variable-width produce same result" do
      {:ok, [{:string_value, _, surrogate_result}]} =
        Lexer.tokenize(~S("\uD83D\uDCA9"))

      {:ok, [{:string_value, _, variable_result}]} =
        Lexer.tokenize(~S("\u{1F4A9}"))

      assert surrogate_result == variable_result
    end
  end

  describe "emoji and supplementary plane characters" do
    test "parses direct emoji in string" do
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~s("Hello!"))

      assert to_string(value) == ~s("Hello!")
    end

    test "parses multiple emojis" do
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~s(""))

      assert to_string(value) == ~s("")
    end

    test "parses emoji with skin tone modifier" do
      # Thumbs up with light skin tone
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~s(""))

      assert to_string(value) == ~s("")
    end

    test "parses flag emoji (regional indicator symbols)" do
      # US flag (two regional indicators)
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~s(""))

      assert to_string(value) == ~s("")
    end

    test "parses ancient script characters" do
      # Egyptian hieroglyph A001
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~S("\u{13000}"))

      assert to_string(value) == "\"\u{13000}\""
    end

    test "parses mathematical symbols" do
      # Mathematical bold capital A
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~S("\u{1D400}"))

      assert to_string(value) == "\"\u{1D400}\""
    end
  end

  describe "invalid Unicode escape rejection" do
    test "rejects lone high surrogate" do
      # \uD800 alone is invalid
      assert {:error, :invalid_unicode_escape, message, _loc} = Lexer.tokenize(~S("\uD800"))
      assert message =~ "surrogate"
    end

    test "rejects lone low surrogate" do
      # \uDC00 alone is invalid
      assert {:error, :invalid_unicode_escape, message, _loc} = Lexer.tokenize(~S("\uDC00"))
      assert message =~ "surrogate"
    end

    test "rejects high surrogate at end of string" do
      # High surrogate at end with no pair
      assert {:error, :invalid_unicode_escape, message, _loc} = Lexer.tokenize(~S("\uD83D"))
      assert message =~ "surrogate"
    end

    test "rejects high surrogate not followed by low surrogate" do
      # High surrogate followed by non-surrogate
      assert {:error, :invalid_unicode_escape, message, _loc} = Lexer.tokenize(~S("\uD83D\u0041"))
      assert message =~ "surrogate"
    end

    test "rejects surrogate in variable-width escape" do
      # \u{D800} - surrogate in variable-width form
      assert {:error, :invalid_unicode_escape, message, _loc} = Lexer.tokenize(~S("\u{D800}"))
      assert message =~ "Invalid Unicode scalar value"
    end

    test "rejects out of range variable-width escape" do
      # \u{110000} - beyond Unicode range
      assert {:error, :invalid_unicode_escape, message, _loc} = Lexer.tokenize(~S("\u{110000}"))
      assert message =~ "Invalid Unicode scalar value"
    end

    test "rejects very large value" do
      # \u{FFFFFF} - way beyond Unicode range
      assert {:error, :invalid_unicode_escape, message, _loc} = Lexer.tokenize(~S("\u{FFFFFF}"))
      assert message =~ "Invalid Unicode scalar value"
    end
  end

  describe "block strings with Unicode" do
    test "parses block string with Unicode" do
      query = ~s("""Hello World""")

      assert {:ok, [{:block_string_value, {1, 1}, value}]} =
               Lexer.tokenize(query)

      assert to_string(value) == ~s("""Hello World""")
    end

    test "parses block string with emoji" do
      query = ~s("""Hello ! World""")

      assert {:ok, [{:block_string_value, {1, 1}, value}]} =
               Lexer.tokenize(query)

      assert to_string(value) == ~s("""Hello ! World""")
    end

    test "parses multiline block string with Unicode" do
      query = """
      \"\"\"
      Line 1: Hello
      Line 2:
      Line 3: World
      \"\"\"
      """

      assert {:ok, [{:block_string_value, {1, 1}, _value}]} =
               Lexer.tokenize(query)
    end

    test "block strings preserve raw Unicode (no escape processing)" do
      # Block strings should NOT process \uXXXX escapes
      query = ~S("""\u0041""")

      assert {:ok, [{:block_string_value, {1, 1}, value}]} =
               Lexer.tokenize(query)

      # The escape sequence should remain as-is
      assert to_string(value) == ~S("""\u0041""")
    end
  end

  describe "integration with parser" do
    defp run(input) do
      with {:ok, %{input: input}} <- Absinthe.Phase.Parse.run(input) do
        {:ok, input}
      end
    end

    defp get_string_value(result) do
      path = [
        Access.key!(:definitions),
        Access.at(0),
        Access.key!(:selection_set),
        Access.key!(:selections),
        Access.at(0),
        Access.key!(:arguments),
        Access.at(0),
        Access.key!(:value),
        Access.key!(:value)
      ]

      get_in(result, path)
    end

    test "parses query with BMP Unicode escape" do
      query = ~S"""
      query {
        user(name: "\u00F3")
      }
      """

      assert {:ok, result} = run(query)
      assert get_string_value(result) == "\u00F3"
    end

    test "parses query with extended Unicode escape" do
      query = ~S"""
      query {
        user(name: "\u{1F600}")
      }
      """

      assert {:ok, result} = run(query)
      assert get_string_value(result) == "\u{1F600}"
    end

    test "parses query with surrogate pair" do
      query = ~S"""
      query {
        user(name: "\uD83D\uDE00")
      }
      """

      assert {:ok, result} = run(query)
      assert get_string_value(result) == "\u{1F600}"
    end

    test "parses query with direct emoji" do
      query = """
      query {
        user(name: "Hello !")
      }
      """

      assert {:ok, result} = run(query)
      assert get_string_value(result) == "Hello !"
    end

    test "parses query with mixed escape styles" do
      query = ~S"""
      query {
        user(name: "\u0041\u{42}C")
      }
      """

      assert {:ok, result} = run(query)
      assert get_string_value(result) == "ABC"
    end

    test "rejects query with invalid Unicode escape" do
      query = ~S"""
      query {
        user(name: "\uD800")
      }
      """

      assert {:error, _} = run(query)
    end
  end

  describe "Unicode in field names (spec compliance check)" do
    # GraphQL spec: Names must match /[_A-Za-z][_0-9A-Za-z]*/
    # Unicode is NOT allowed in names per spec
    # Note: The lexer doesn't reject Unicode in positions where names are expected,
    # but it won't parse them as names. This is handled at the parser level.

    test "Unicode outside strings is ignored by lexer" do
      # The lexer encounters Unicode characters outside of strings
      # They are treated as ignored/whitespace since they don't match token patterns
      # This means bare Unicode characters between valid tokens are skipped
      query = "{ }"

      # The lexer ignores unknown characters and successfully parses the braces
      assert {:ok, tokens} = Lexer.tokenize(query)
      # Only the braces are parsed; Unicode is ignored as whitespace
      assert [{:"{", _}, {:"}", _}] = tokens
    end

    test "allows valid ASCII names" do
      query = "{ valid_Name123 }"

      assert {:ok,
              [
                {:"{", _},
                {:name, _, ~c"valid_Name123"},
                {:"}", _}
              ]} = Lexer.tokenize(query)
    end

    test "names starting with underscore are valid" do
      query = "{ _privateName }"

      assert {:ok,
              [
                {:"{", _},
                {:name, _, ~c"_privateName"},
                {:"}", _}
              ]} = Lexer.tokenize(query)
    end
  end

  describe "edge cases" do
    test "empty string" do
      assert {:ok, [{:string_value, {1, 1}, ~c"\"\""}]} =
               Lexer.tokenize(~s(""))
    end

    test "string with only escape sequence" do
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~S("\u0041"))

      assert to_string(value) == "\"A\""
    end

    test "consecutive escape sequences" do
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~S("\u0041\u{42}"))

      assert to_string(value) == "\"AB\""
    end

    test "escape sequence at string boundaries" do
      # Escape at start
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~S("\u0041bc"))

      assert to_string(value) == "\"Abc\""

      # Escape at end
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~S("ab\u0043"))

      assert to_string(value) == "\"abC\""
    end

    test "long string with many escape sequences" do
      # Create string with 100 escape sequences
      escapes = String.duplicate(~S(\u0041), 100)
      query = ~s("#{escapes}")

      assert {:ok, [{:string_value, {1, 1}, value}]} = Lexer.tokenize(query)
      assert to_string(value) == "\"" <> String.duplicate("A", 100) <> "\""
    end

    test "control characters via escape" do
      # Null, bell, backspace, tab, newline, etc.
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~S("\u0000\u0007\u0008\t\n"))

      # Contains control characters
      assert is_list(value)
    end

    test "zero-width characters" do
      # Zero-width space (U+200B)
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~S("\u200B"))

      assert to_string(value) == "\"\u200B\""
    end

    test "right-to-left mark" do
      # Right-to-left mark (U+200F)
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~S("\u200F"))

      assert to_string(value) == "\"\u200F\""
    end

    test "byte order mark" do
      # BOM (U+FEFF)
      assert {:ok, [{:string_value, {1, 1}, value}]} =
               Lexer.tokenize(~S("\uFEFF"))

      assert to_string(value) == "\"\uFEFF\""
    end
  end
end
