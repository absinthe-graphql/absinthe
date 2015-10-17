defmodule ParseTest do
  use ExUnit.Case

  test "returns a document" do
    assert {:ok, %{__struct__: ExGraphQL.AST.Document}} = ExGraphQL.parse("{ hello }")
  end

end
