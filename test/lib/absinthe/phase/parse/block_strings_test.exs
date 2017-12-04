defmodule Absinthe.Phase.Parse.BlockStringsTest do
  use Absinthe.Case, async: true

  it "parses a query with a block string argument literal and no newlines" do
    assert {:ok, result} = run(~S<{ post(title: "single", body: """text""") { name } }>)
    assert "text" == extract_body(result)
  end

  it "parses a query with a block string argument that contains a quote" do
    assert {:ok, result} = run(~S<{ post(title: "single", body: """text "here""") { name } }>)
    assert "text \"here" == extract_body(result)
  end

  it "parses a query with a block string argument that contains various escapes" do
    assert {:ok, result} = run(~s<{ post(title: "single", body: """unescaped \\n\\r\\b\\t\\f\\u1234""") { name } }>)
    assert "unescaped \\n\\r\\b\\t\\f\\u1234" == extract_body(result)
  end

  it "parses a query with a block string argument that contains various slashes" do
    assert {:ok, result} = run(~s<{ post(title: "single", body: """slashes \\\\ \\/""") { name } }>)
    assert "slashes \\\\ \\/" == extract_body(result)
  end


  @input [
    "",
    "    Hello,",
    "      World!",
    "",
    "    Yours,",
    "      GraphQL."
  ]
  @result [
    "Hello,",
    "  World!",
    "",
    "Yours,",
    "  GraphQL."
  ]
  it "parses a query with a block string argument, removing uniform indentation from a string" do
    assert {:ok, result} = run(~s<{ post(title: "single", body: """#{lines(@input)}""") { name } }>)
    assert lines(@result) == extract_body(result)
  end

  @input [
    "",
    "",
    "    Hello,",
    "      World!",
    "",
    "    Yours,",
    "      GraphQL.",
    "",
    ""
  ]
  @result [
    "Hello,",
    "  World!",
    "",
    "Yours,",
    "  GraphQL."
  ]
  it "parses a query with a block string argument, removing empty leading and trailing lines" do
    assert {:ok, result} = run(~s<{ post(title: "single", body: """#{lines(@input)}""") { name } }>)
    assert lines(@result) == extract_body(result)
  end

  @input [
    "  ",
    "        ",
    "    Hello,",
    "      World!",
    "",
    "    Yours,",
    "      GraphQL.",
    "        ",
    "  "
  ]
  @result [
    "Hello,",
    "  World!",
    "",
    "Yours,",
    "  GraphQL."
  ]
  it "parses a query with a block string argument, removing blank leading and trailing lines" do
    assert {:ok, result} = run(~s<{ post(title: "single", body: """#{lines(@input)}""") { name } }>)
    assert lines(@result) == extract_body(result)
  end

  @input [
    "    Hello,",
    "      World!",
    "",
    "    Yours,",
    "      GraphQL."
  ]
  @result [
    "    Hello,",
    "  World!",
    "",
    "Yours,",
    "  GraphQL."
  ]
  it "parses a query with a block string argument, retaining indentation from first line" do
    assert {:ok, result} = run(~s<{ post(title: "single", body: """#{lines(@input)}""") { name } }>)
    assert lines(@result) == extract_body(result)
  end

  @input [
    "               ",
    "    Hello,     ",
    "      World!   ",
    "               ",
    "    Yours,     ",
    "      GraphQL. ",
    "               "
  ]
  @result [
    "Hello,     ",
    "  World!   ",
    "           ",
    "Yours,     ",
    "  GraphQL. "
  ]
  it "parses a query with a block string argument, not altering trailing spaces" do
    assert {:ok, result} = run(~s<{ post(title: "single", body: """#{lines(@input)}""") { name } }>)
    assert lines(@result) == extract_body(result)
  end

  it "parses a query with a block string argument literal and carriage returns, normalizing" do
    assert {:ok, result} = run(~s<{ post(title: "single", body: """text\nline\r\nanother""") { name } }>)
    assert "text\nline\nanother" == extract_body(result)
  end


  it "parses a query with a block string argument literal with escaped triple quotes and no newlines" do
    assert {:ok, result} = run(~S<{ post(title: "single", body: """text\""" """) { name } }>)
    assert ~S<text""" > == extract_body(result)
  end

  it "parses a query with a block string argument literal and newlines" do
    assert {:ok, result} = run(
      ~s<{ post(title: "single", body: """
             text
      """) { name } }>)
      assert "\n             text\n      " == extract_body(result)
  end

  it "parses a query with a block string argument literal and escaped triple quotes and newlines" do
    assert {:ok, result} = run(
      ~S<{ post(title: "single", body: """
             text\"""
      """) { name } }>)
    assert ~s<\n             text\"\"\"\n      > == extract_body(result)
  end

  it "returns an error for a bad byte" do
    assert {:error, err} = run(~s<{ post(title: "single", body: """trying to escape a \u0000 byte""") { name } }>)
    assert "syntax error" <> _ = extract_error_message(err)
  end

  defp extract_error_message(err) do
    get_in(err,
      [
        Access.key(:execution),
        Access.key(:validation_errors),
        Access.at(0),
        Access.key(:message)
      ]
    )
  end

  defp extract_body(value) do
    get_in(value,
      [
        Access.key(:definitions),
        Access.at(0),
        Access.key(:selection_set),
        Access.key(:selections),
        Access.at(0),
        Access.key(:arguments),
        Access.at(1),
        Access.key(:value),
        Access.key(:value)
      ]
    )
  end

  def run(input) do
    with {:ok, %{input: input}} <- Absinthe.Phase.Parse.run(input) do
      {:ok, input}
    end
  end

  defp lines(input) do
    input
    |> Enum.join("\n")
  end

end
