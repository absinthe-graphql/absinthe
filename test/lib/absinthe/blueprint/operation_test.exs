defmodule Absinthe.Blueprint.OperationTest do
  use Absinthe.Case, async: true

  alias Absinthe.Blueprint

  @query """
  query Foo($showFoo: Boolean = true) {
    foo @include(if: $showFoo)
  }
  """

  describe ".from_ast" do

    it "builds a Operation.t" do
      assert %Blueprint.Operation{name: "Foo", type: :query, variable_definitions: [%Blueprint.VariableDefinition{name: "showFoo", type: %Blueprint.NamedType{name: "Boolean"}, default_value: %Blueprint.Input.Boolean{value: true}}]} = from_input(@query)
    end

  end

  defp from_input(text) do
    doc = Absinthe.parse!(text)

    doc
    |> extract_ast_node
    |> Blueprint.Operation.from_ast(doc)
  end

  defp extract_ast_node(%Absinthe.Language.Document{definitions: [node]}) do
    node
  end

end
