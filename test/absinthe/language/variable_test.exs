defmodule Absinthe.Language.VariableTest do
  use Absinthe.Case, async: true

  alias Absinthe.{Blueprint, Language}

  @query """
  query Foo($input: InputObjectSettingFoo = {foo: 2}) {
    foo(input: $input) {
      baz
    }
  }
  """

  describe "converting to Blueprint" do
    test "builds an Input.Variable.t" do
      assert %Blueprint.Input.Variable{name: "input"} = from_input(@query)
    end
  end

  defp from_input(text) do
    {:ok, %{input: doc}} = Absinthe.Phase.Parse.run(text)

    doc
    |> extract_ast_node
    |> Blueprint.Draft.convert(doc)
  end

  defp extract_ast_node(%Language.Document{definitions: [node]}) do
    node.selection_set.selections
    |> List.first()
    |> Map.get(:arguments)
    |> List.first()
    |> Map.get(:value)
  end
end
