defmodule Absinthe.Language.FieldTest do
  use Absinthe.Case, async: true

  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.{Input}

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
    test "builds a Field.t" do
      assert %Blueprint.Document.Field{
               name: "foo",
               arguments: [
                 %Input.Argument{
                   name: "input",
                   input_value: %Input.RawValue{
                     content: %Input.Object{
                       fields: [
                         %Input.Field{
                           name: "foo",
                           input_value: %Input.RawValue{content: %Input.Integer{value: 2}}
                         }
                       ]
                     }
                   }
                 }
               ],
               source_location: %Blueprint.SourceLocation{line: 2}
             } = from_input(@query)
    end

    test "builds a Field.t when using a directive" do
      assert %Blueprint.Document.Field{
               name: "foo",
               directives: [
                 %Blueprint.Directive{
                   name: "include",
                   arguments: [
                     %Input.Argument{
                       name: "if",
                       input_value: %Input.RawValue{content: %Input.Variable{name: "showFoo"}}
                     }
                   ],
                   source_location: %Blueprint.SourceLocation{line: 2}
                 }
               ],
               arguments: [
                 %Input.Argument{
                   name: "input",
                   input_value: %Input.RawValue{
                     content: %Input.Object{
                       fields: [
                         %Input.Field{
                           name: "foo",
                           input_value: %Input.RawValue{content: %Input.Integer{value: 2}}
                         }
                       ]
                     }
                   }
                 }
               ],
               source_location: %Blueprint.SourceLocation{line: 2}
             } = from_input(@query_with_directive)
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
  end
end
