defmodule Absinthe.Phase.Parse.LanguageTest do
  use Absinthe.Case, async: true

  @moduletag :parser

  test "parses kitchen-sink.graphql" do
    filename = Path.join(__DIR__, "../../../support/fixtures/language/kitchen-sink.graphql")
    input = File.read!(filename)
    assert {:ok, _} = run(input)
  end

  test "parses schema-kitchen-sink.graphql" do
    filename =
      Path.join(__DIR__, "../../../support/fixtures/language/schema-kitchen-sink.graphql")

    input = File.read!(filename)
    assert {:ok, _} = run(input)
  end

  test "parses schema-with-emojis.graphql" do
    filename = Path.join(__DIR__, "../../../support/fixtures/language/schema-with-emojis.graphql")

    input = File.read!(filename)
    assert {:ok, _} = run(input)
  end

  def run(input) do
    with {:ok, %{input: input}} <- Absinthe.Phase.Parse.run(input) do
      {:ok, input}
    end
  end
end
