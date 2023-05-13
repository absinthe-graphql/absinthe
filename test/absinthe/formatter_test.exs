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
end
