defmodule Absinthe.Language.VariableDefinitionTest do
  use Absinthe.Case, async: true

  alias Absinthe.{Blueprint, Language}

  @query """
  query Foo($showFoo: Boolean = true @bar(a: 1)) {
    foo @include(if: $showFoo)
  }
  """

  describe "converting to Blueprint" do
    test "builds a VariableDefinition.t" do
      assert %Blueprint.Document.VariableDefinition{
               name: "showFoo",
               directives: [%Blueprint.Directive{name: "bar"}],
               type: %Blueprint.TypeReference.Name{name: "Boolean"},
               default_value: %Blueprint.Input.Boolean{value: true},
               source_location: %Blueprint.SourceLocation{line: 1}
             } = from_input(@query)
    end
  end

  defp from_input(text) do
    {:ok, %{input: doc}} = Absinthe.Phase.Parse.run(text)

    doc
    |> extract_ast_node
    |> Blueprint.Draft.convert(doc)
  end

  defp extract_ast_node(%Language.Document{definitions: [node]}) do
    node.variable_definitions
    |> List.first()
  end
end
