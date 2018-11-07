defmodule Absinthe.Phase.Parse.BlockStringsTest do
  use Absinthe.Case, async: true

  @moduletag :parser

  test "parses a query with a block string literal and no newlines" do
    assert {:ok, result} = run(~S<{ post(title: "single", body: """text""") { name } }>)
    assert "text" == extract_body(result)
  end

  test "parses a query with a block string argument that contains a quote" do
    assert {:ok, result} = run(~S<{ post(title: "single", body: """text "here""") { name } }>)
    assert "text \"here" == extract_body(result)
  end

  test "parses a query with a block string literal that contains various escapes" do
    assert {:ok, result} =
             run(
               ~s<{ post(title: "single", body: """unescaped \\n\\r\\b\\t\\f\\u1234""") { name } }>
             )

    assert "unescaped \\n\\r\\b\\t\\f\\u1234" == extract_body(result)
  end

  test "parses a query with a block string literal that contains various slashes" do
    assert {:ok, result} =
             run(~s<{ post(title: "single", body: """slashes \\\\ \\/""") { name } }>)

    assert "slashes \\\\ \\/" == extract_body(result)
  end

  test "parses attributes when there are escapes" do
    assert {:ok, result} = run(~s<{ post(title: "title", body: "body\\\\") { name } }>)
    assert "body\\" == extract_body(result)

    assert {:ok, result} = run(~s<{ post(title: "title\\\\", body: "body") { name } }>)
    assert "body" == extract_body(result)
  end

  test "parse attributes where there are escapes on multiple lines" do
    assert {:ok, result} = run(~s<{ post(
        title: "title",
        body: "body\\\\"
      ) { name } }>)
    assert "body\\" == extract_body(result)

    assert {:ok, result} = run(~s<{ post(
        title: "title\\\\",
        body: "body"
      ) { name } }>)
    assert "body" == extract_body(result)
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
  test "parses a query with a block string literal, removing uniform indentation from a string" do
    assert {:ok, result} =
             run(~s<{ post(title: "single", body: """#{lines(@input)}""") { name } }>)

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
  test "parses a query with a block string literal, removing empty leading and trailing lines" do
    assert {:ok, result} =
             run(~s<{ post(title: "single", body: """#{lines(@input)}""") { name } }>)

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
  test "parses a query with a block string literal, removing blank leading and trailing lines" do
    assert {:ok, result} =
             run(~s<{ post(title: "single", body: """#{lines(@input)}""") { name } }>)

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
  test "parses a query with a block string literal, retaining indentation from first line" do
    assert {:ok, result} =
             run(~s<{ post(title: "single", body: """#{lines(@input)}""") { name } }>)

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
  test "parses a query with a block string literal, not altering trailing spaces" do
    assert {:ok, result} =
             run(~s<{ post(title: "single", body: """#{lines(@input)}""") { name } }>)

    assert lines(@result) == extract_body(result)
  end

  test "parses a query with a block string literal and carriage returns, normalizing" do
    assert {:ok, result} =
             run(~s<{ post(title: "single", body: """text\nline\r\nanother""") { name } }>)

    assert "text\nline\nanother" == extract_body(result)
  end

  test "parses a query with a block string literal with escaped triple quotes and no newlines" do
    assert {:ok, result} = run(~S<{ post(title: "single", body: """text\""" """) { name } }>)
    assert ~S<text""" > == extract_body(result)
  end

  test "returns an error for a bad byte" do
    assert {:error, err} =
             run(
               ~s<{ post(title: "single", body: """trying to escape a \u0000 byte""") { name } }>
             )

    assert "Parsing failed at" <> _ = extract_error_message(err)
  end

  test "parses a query with a block string literal as a variable default" do
    assert {:ok, result} =
             run(
               ~S<query ($body: String = """text""") { post(title: "single", body: $body) { name } }>
             )

    assert "text" ==
             get_in(result, [
               Access.key(:definitions, []),
               Access.at(0),
               Access.key(:variable_definitions, %{}),
               Access.at(0),
               Access.key(:default_value, %{}),
               Access.key(:value, nil)
             ])
  end

  defp extract_error_message(err) do
    get_in(err, [
      Access.key(:execution, %{}),
      Access.key(:validation_errors, []),
      Access.at(0),
      Access.key(:message, nil)
    ])
  end

  defp extract_body(value) do
    get_in(value, [
      Access.key(:definitions),
      Access.at(0),
      Access.key(:selection_set),
      Access.key(:selections),
      Access.at(0),
      Access.key(:arguments),
      Access.at(1),
      Access.key(:value),
      Access.key(:value)
    ])
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
