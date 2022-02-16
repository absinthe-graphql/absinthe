defmodule Absinthe.FormatterTest do
  use Absinthe.Case, async: true

  @query """
  {
    version
  }
  """
  test "formats a document" do
    assert Absinthe.Formatter.format(@query) == "{\n  version\n}\n"
  end

  @query """
    query AQuery {
      aVeryLongLineThatExceedsOneHundredAndTwentyCharactersAsWasTheDefault(thereAreMultipleArgsAsWell: ["A"], hereIsAnother: true) { id name }
    }
  """
  test "creates line breaks at 80 width by default" do
    assert Absinthe.Formatter.format(@query) == """
           query AQuery {
             aVeryLongLineThatExceedsOneHundredAndTwentyCharactersAsWasTheDefault(
               thereAreMultipleArgsAsWell: ["A"], hereIsAnother: true
             ) {
               id
               name
             }
           }
           """
  end
end
