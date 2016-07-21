defmodule Absinthe.Phase.Document.FlattenTest do
  use Absinthe.Case, async: true

  alias Absinthe.{Blueprint, Phase, Pipeline}

  defmodule Schema do
    use Absinthe.Schema

    query do
      field :foo, :foo do
        arg :id, non_null(:id)
      end
      field :more, :string
    end

    object :foo do
      field :name, :string
      field :age, :integer
    end

    object :not_foo do
      field :name, :string
      field :age, :integer
    end

  end

 @pre_pipeline Enum.take_while(Pipeline.for_document(Schema, %{"id" => 4}), fn
    Phase.Document.Flatten ->
      false
    _ ->
      true
  end)

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
    fragment QueryFields on QueryRoot {
      ... on QueryRoot {
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
        %Blueprint.Document.Field{name: "more", type_conditions: [%Blueprint.TypeReference.Name{name: "QueryRoot"}]}
      ] = op.fields
    end
  end

  def input(query) do
    {:ok, result} = blueprint(query)
    |> Phase.Document.Flatten.run

    result
  end

  defp blueprint(query) do
    {:ok, blueprint} = Pipeline.run(query, @pre_pipeline)
    blueprint
  end

end
