defmodule Absinthe.Phase.Document.DirectivesTest do
  use Absinthe.Case, async: true

  alias Absinthe.{Blueprint, Phase, Pipeline}

  defmodule Schema do
    use Absinthe.Schema

    query do
      field :books, list_of(:book)
    end

    object :book do
      field :name, :string
      field :categories, list_of(:category)
    end

    object :category do
      field :name, :string
    end
  end

  @query """
  query Q($cats: Boolean!) {
    books {
      name
      categories @include(if: $cats) {
        ... CategoryName
      }
    }
  }
  fragment CategoryName on Category {
    name
  }
  """

  describe ".run with built-in @include" do
    test "returns a blueprint" do
      {:ok, result} = input(@query, %{"cats" => true})
      assert %Blueprint{} = result
    end

    test "adds a :skip flag" do
      {:ok, result} = input(@query, %{"cats" => false})
      node = named(result, Blueprint.Document.Field, "categories")
      assert Blueprint.flagged?(node, :skip)
    end

    test "adds an :include flag" do
      {:ok, result} = input(@query, %{"cats" => true})
      node = named(result, Blueprint.Document.Field, "categories")
      assert Blueprint.flagged?(node, :include)
    end
  end

  def input(query, values) do
    blueprint(query, values)
    |> Phase.Document.Directives.run()
  end

  defp blueprint(query, values) do
    {:ok, blueprint, _} = Pipeline.run(query, pre_pipeline(values))
    blueprint
  end

  # Get the document pipeline up to (but not including) this phase
  defp pre_pipeline(values) do
    Pipeline.for_document(Schema, variables: values, jump_phases: false)
    |> Pipeline.before(Phase.Document.Directives)
  end

  defp named(scope, mod, name) do
    Blueprint.find(scope, fn
      %{__struct__: ^mod, name: ^name} ->
        true

      _ ->
        false
    end)
  end
end
