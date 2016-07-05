defmodule Absinthe.Language.OperationDefinitionTest do
  use Absinthe.Case, async: true

  alias Absinthe.{Blueprint, Language}

  @query """
  query Foo($showFoo: Boolean = true) {
    foo @include(if: $showFoo)
  }
  """

  describe "converting to Blueprint" do

    it "builds a Operation.t" do
      assert %Blueprint.Operation{name: "Foo", type: :query, variable_definitions: [%Blueprint.VariableDefinition{name: "showFoo", type: %Blueprint.TypeReference.Name{name: "Boolean"}, default_value: %Blueprint.Input.Boolean{value: true}}]} = from_input(@query)
    end

  end

  defp from_input(text) do
    {:ok, doc} = Absinthe.Phase.Parse.run(text)

    doc
    |> extract_ast_node
    |> Blueprint.Draft.convert(doc)
  end

  defp extract_ast_node(%Language.Document{definitions: [node]}) do
    node
  end

end
