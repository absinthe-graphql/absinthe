defmodule Absinthe.Phase.Document.FlattenTest do
  use Absinthe.Case, async: true

  alias Absinthe.{Blueprint, Phase, Pipeline}

  defmodule Schema do
    use Absinthe.Schema

    query name: "QueryRoot" do
      field :foo, :foo do
        arg :id, non_null(:id)
      end
      field :more, :string
    end

    object :foo do
      field :name, :string
      field :age, :integer
      field :gender, :string
    end

    object :not_foo do
      field :name, :string
      field :age, :integer
    end

  end

  @query """
    query Foo($id: ID!) {
      foo(id: $id) {
        gender
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
      result = input(@query, %{"id" => 4})
      assert ~w(foo more) == get_in(result.operations, [Access.at(0), Access.key!(:fields), Access.all(), Access.key!(:name)])
      assert ~w(gender name name age age) == get_in(result.operations, [Access.at(0), Access.key!(:fields), Access.at(0), Access.key!(:fields), Access.all(), Access.key!(:name)])
    end
  end

  @query """
    query Foo($id: ID!, $inc: Boolean!) {
      foo(id: $id) {
        gender @include(if: $inc)
        ... FooFields @include(if: $inc)
        ... NotFooFields
        ... on Foo @include(if: $inc) {
          age
        }
        ... on NotFoo {
          age @include(if: $inc)
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

  describe "a deeply fragment-nested document using directives" do
    it "has its selections flattened to fields" do
      result = input(@query, %{"id" => 4, "inc" => false})
      op = result.operations |> List.first
      assert ~w(foo more) == get_in(op.fields, [Access.all(), Access.key!(:name)])
      assert ~w(name) == get_in(op.fields, [Access.at(0), Access.key!(:fields), Access.all(), Access.key!(:name)])
    end
  end

  @introspection_query """
  query Q {
    __type(name: "ProfileInput") {
      name
      kind
      fields {
        name
      }
      ...Inputs
    }
  }

  fragment Inputs on __Type {
    inputFields { name }
  }
  """

  describe "an introspection query" do

    it "has its selections flattened to fields" do
      pre = Pipeline.for_document(ContactSchema)
      |> Pipeline.before(Phase.Document.Flatten)
      {:ok, blueprint, _} = Pipeline.run(@introspection_query, pre)
      {:ok, result} = Phase.Document.Flatten.run(blueprint)
      op = Blueprint.current_operation(result)
      assert Blueprint.find(op, fn
        %Blueprint.Document.Field{name: "inputFields", fields: [%{name: "name"}]} ->
          true
        _ ->
          false
      end), "Could not find the `name` field flattened inside `inputFields`"
    end
  end

  def input(query, variables \\ %{}) do
    {:ok, result} = blueprint(query, variables)
    |> Phase.Document.Flatten.run

    result
  end

  defp blueprint(query, variables) do
    {:ok, blueprint, _phases} = Pipeline.run(query, pre_pipeline(variables))
    blueprint
  end

  defp pre_pipeline(variables) do
    Pipeline.for_document(Schema, variables: variables)
    |> Pipeline.before(Phase.Document.Flatten)
  end

end
