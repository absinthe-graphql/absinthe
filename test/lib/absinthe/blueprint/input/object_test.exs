defmodule Absinthe.Blueprint.Input.ObjectTest do
  use Absinthe.Case, async: true

  alias Absinthe.Blueprint

  @query """
  {
    foo(input: {foo: 2}) {
      baz
    }
  }
  """

  describe ".from_ast" do

    it "builds an Input.Object.t" do
      assert %Blueprint.Input.Object{fields: [%Blueprint.Input.Field{name: "foo", value: %Blueprint.Input.Integer{value: 2}}]} = from_input(@query)
    end

  end

  defp from_input(text) do
    doc = Absinthe.parse!(text)

    doc
    |> extract_ast_node
    |> Blueprint.Input.Object.from_ast(doc)
  end

  defp extract_ast_node(%Absinthe.Language.Document{definitions: [node]}) do
    node.selection_set.selections
    |> List.first
    |> Map.get(:arguments)
    |> List.first
    |> Map.get(:value)
  end

end
