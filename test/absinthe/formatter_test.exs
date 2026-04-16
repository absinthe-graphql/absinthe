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

  test "keeps comments" do
    assert Absinthe.Formatter.format("""
           # Comment before
           query { entity {
             # Comment within
             id
           }}
           # Comment after
           """) == """
           # Comment before
           query {
             entity {
               # Comment within
               id
             }
           }
           # Comment after
           """
  end
end
