defmodule Absinthe.Phase.Document.SchemaTest do
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

  @pre_pipeline [Phase.Parse, Phase.Blueprint]

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

    it "sets the root schema field" do
      {:ok, result} = input(@query)
      assert result.schema == Schema
    end

    it "sets directive schema nodes" do
      {:ok, result} = input(@query)
      directive = Blueprint.find(result, fn
        %Blueprint.Directive{name: "include"} ->
          true
        _ ->
          false
      end)
      assert %Absinthe.Type.Directive{name: "include"} = directive.schema_node
    end

  end

  def input(query) do
    blueprint(query)
    |> Phase.Document.Schema.run(Schema)
  end

  defp blueprint(query) do
    {:ok, blueprint} = Pipeline.run(query, @pre_pipeline)
    blueprint
  end

end
