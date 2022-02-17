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
      aQuery(thereAreMultipleArgsAsWell: ["A"], hereIsAnother: true) { id name
      field(singleArg: OK)
      multipleArgs(argOne: OK argTwo: OK)
    }
    }
  """
  test "creates line breaks at 80 width by default" do
    assert Absinthe.Formatter.format(@query) == """
           query AQuery {
             aQuery(
               thereAreMultipleArgsAsWell: ["A"]
               hereIsAnother: true
             ) {
               id
               name
               field(singleArg: OK)
               multipleArgs(
                 argOne: OK
                 argTwo: OK
               )
             }
           }
           """
  end
end
