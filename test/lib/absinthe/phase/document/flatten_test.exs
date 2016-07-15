defmodule Absinthe.Phase.Document.FlattenTest do
  use Absinthe.Case, async: true

  alias Absinthe.{Blueprint, Phase, Pipeline}

  @pre_pipeline [Phase.Parse, Phase.Blueprint, {Phase.Document.Variables, %{}}, Phase.Document.Arguments]

  @query """
    query Foo($id: ID!) {
      foo(id: $id) {
        bar
        ... FooFields
        ... NotFooFields
        ... on Foo {
          age
        }
        ... on NotFoo {
          age
        }
      }
      ... QueryFields
    }
    fragment QueryFields on Query {
      ... on Query {
        more
      }
    }
    fragment FooFields on Foo {
      name
    }
    fragment NotFooFields on NotFoo {
      name
    }
  """

  describe "a deeply fragment-nested document" do
    it "has its selections flattened to fields" do
      result = input(@query)
      op = result.operations |> List.first
      assert [
        %Blueprint.Document.Field{
          name: "foo",
          type_conditions: [],
          fields: [
            %Blueprint.Document.Field{name: "bar", type_conditions: []},
            %Blueprint.Document.Field{name: "name", type_conditions: [%Blueprint.TypeReference.Name{name: "Foo"}]},
            %Blueprint.Document.Field{name: "name", type_conditions: [%Blueprint.TypeReference.Name{name: "NotFoo"}]},
            %Blueprint.Document.Field{name: "age", type_conditions: [%Blueprint.TypeReference.Name{name: "Foo"}]},
            %Blueprint.Document.Field{name: "age", type_conditions: [%Blueprint.TypeReference.Name{name: "NotFoo"}]},
          ],
        },
        %Blueprint.Document.Field{name: "more", type_conditions: [%Blueprint.TypeReference.Name{name: "Query"}]}
      ] = op.fields
    end
  end

  def input(query) do
    {:ok, result} = blueprint(query)
    |> Phase.Document.Flatten.run([])

    result
  end

  defp blueprint(query) do
    {:ok, blueprint} = Pipeline.run(query, @pre_pipeline)
    blueprint
  end

end
