defmodule ExGraphQL.Language.ParseTest do
  use ExUnit.Case

  test "returns a document" do
    assert {:ok, %{__struct__: ExGraphQL.Language.Document}} = ExGraphQL.parse("{ hello }")
  end

end
