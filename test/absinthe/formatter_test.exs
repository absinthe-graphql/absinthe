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

  test "keeps single-line comments" do
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

  test "keeps multi-line comments" do
    assert Absinthe.Formatter.format("""
           \"\"\"
           Query the entity
               and its ID
             \"\"\"
           query { entity {
             id
           }}
           """) == """
           \"\"\"
           Query the entity
               and its ID
           \"\"\"
           query {
             entity {
               id
             }
           }
           """
  end
end
