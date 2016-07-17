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
      field :name
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

  describe ".run" do

    it "returns a blueprint" do
      {:ok, result} = input(@query, %{})
      assert %Blueprint{} = result
    end

  end

  def input(query, values) do
    blueprint(query, values)
    |> Phase.Document.Directives.run
  end

  defp blueprint(query, values) do
    {:ok, blueprint} = Pipeline.run(query, pre_pipeline(values))
    blueprint
  end

  # Get the document pipeline up to (but not including) this phase
  defp pre_pipeline(values) do
    Pipeline.for_document(Schema, values)
    |> Enum.take_while(fn
      Phase.Document.Directives ->
        false
      _ ->
        true
    end)
  end

end
