defmodule Absinthe.Language.FieldTest do
  use Absinthe.Case, async: true

  alias Absinthe.Blueprint

  @query """
  {
    foo(input: {foo: 2}) {
      baz
    }
  }
  """

  @query_with_directive """
  query Bar($showFoo: Boolean!) {
    foo(input: {foo: 2}) @include(if: $showFoo) {
      baz
    }
  }
  """

  describe "converting to Blueprint" do

    it "builds a Field.t" do
      assert %Blueprint.Document.Field{name: "foo", arguments: [%Blueprint.Input.Argument{name: "input", value: %Blueprint.Input.Object{fields: [%Blueprint.Input.Field{name: "foo", value: %Blueprint.Input.Integer{value: 2}}]}}]} = from_input(@query)
    end

    it "builds a Field.t when using a directive" do
      assert %Blueprint.Document.Field{name: "foo", directives: [%Blueprint.Document.Directive{name: "include", arguments: [%Blueprint.Input.Argument{name: "if", value: %Blueprint.Input.Variable{name: "showFoo"}}]}], arguments: [%Blueprint.Input.Argument{name: "input", value: %Blueprint.Input.Object{fields: [%Blueprint.Input.Field{name: "foo", value: %Blueprint.Input.Integer{value: 2}}]}}]} = from_input(@query_with_directive)
    end

  end

  defp from_input(text) do
    {:ok, doc} = Absinthe.Phase.Parse.run(text)

    doc
    |> extract_ast_node
    |> Blueprint.Draft.convert(doc)
  end

  defp extract_ast_node(%Absinthe.Language.Document{definitions: [node]}) do
    node.selection_set.selections
    |> List.first
  end

end
