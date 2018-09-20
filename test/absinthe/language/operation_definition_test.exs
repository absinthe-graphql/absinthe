defmodule Absinthe.Language.OperationDefinitionTest do
  use Absinthe.Case, async: true

  alias Absinthe.{Blueprint, Language}

  @query """
  query Foo($showFoo: Boolean = true) {
    foo @include(if: $showFoo)
  }
  """

  describe "converting to Blueprint" do
    test "builds a Operation.t" do
      assert %Blueprint.Document.Operation{
               name: "Foo",
               type: :query,
               variable_definitions: [
                 %Blueprint.Document.VariableDefinition{
                   name: "showFoo",
                   type: %Blueprint.TypeReference.Name{name: "Boolean"},
                   default_value: %Blueprint.Input.Boolean{value: true}
                 }
               ],
               source_location: %Blueprint.SourceLocation{line: 1}
             } = from_input(@query)
    end

    @query """
    query Foo($showFoo: Boolean = true) {
      foo @include(if: $showFoo)
      ... QueryBits
    }
    fragment QueryBits on Query {
      bar
    }
    """

    test "builds a Operation.t including a named fragment spread" do
      assert %Blueprint.Document.Operation{
               name: "Foo",
               type: :query,
               variable_definitions: [
                 %Blueprint.Document.VariableDefinition{
                   name: "showFoo",
                   type: %Blueprint.TypeReference.Name{name: "Boolean"},
                   default_value: %Blueprint.Input.Boolean{value: true}
                 }
               ],
               source_location: %Blueprint.SourceLocation{line: 1},
               selections: [
                 %Blueprint.Document.Field{name: "foo"},
                 %Blueprint.Document.Fragment.Spread{name: "QueryBits"}
               ]
             } = from_input(@query)
    end
  end

  defp from_input(text) do
    {:ok, %{input: doc}} = Absinthe.Phase.Parse.run(text)

    doc
    |> extract_ast_node
    |> Blueprint.Draft.convert(doc)
  end

  defp extract_ast_node(%Language.Document{definitions: nodes}) do
    nodes
    |> List.first()
  end
end
