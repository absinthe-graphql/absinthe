defmodule Absinthe.Language.InputUnionValueTest do
  use Absinthe.Case, async: true

  alias Absinthe.Blueprint

  @query """
  {
    foo(input: {__typename: "ConcreteType", foo: 2}) {
      baz
    }
  }
  """

  describe "converting to Blueprint" do
    test "builds an Input.Object.t" do
      assert %Blueprint.Input.Object{
               fields: [
                 %Blueprint.Input.Field{
                   name: "__typename",
                   input_value: %Blueprint.Input.RawValue{
                     content: %Blueprint.Input.String{value: "ConcreteType"}
                   }
                 },
                 %Blueprint.Input.Field{
                   name: "foo",
                   input_value: %Blueprint.Input.RawValue{
                     content: %Blueprint.Input.Integer{value: 2}
                   }
                 }
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

  defp extract_ast_node(%Absinthe.Language.Document{definitions: [node]}) do
    node.selection_set.selections
    |> List.first()
    |> Map.get(:arguments)
    |> List.first()
    |> Map.get(:value)
  end
end
