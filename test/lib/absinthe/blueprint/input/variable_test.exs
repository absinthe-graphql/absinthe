defmodule Absinthe.Blueprint.Input.VariableTest do
  use Absinthe.Case, async: true

  alias Absinthe.Blueprint

  @query """
  query Foo($input: InputObjectSettingFoo = {foo: 2}) {
    foo(input: $input) {
      baz
    }
  }
  """

  describe ".from_ast" do

    it "builds an Input.Variable.t" do
      assert %Blueprint.Input.Variable{name: "input"} = from_input(@query)
    end

  end

  defp from_input(text) do
    doc = Absinthe.parse!(text)

    doc
    |> extract_ast_node
    |> Blueprint.Input.Variable.from_ast(doc)
  end

  defp extract_ast_node(%Absinthe.Language.Document{definitions: [node]}) do
    node.selection_set.selections
    |> List.first
    |> Map.get(:arguments)
    |> List.first
    |> Map.get(:value)
  end

end
