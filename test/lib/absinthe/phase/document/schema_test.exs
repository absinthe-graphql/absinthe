defmodule Absinthe.Phase.Document.SchemaTest do
  use Absinthe.Case, async: true

  alias Absinthe.{Blueprint, Phase, Pipeline}

  defmodule Schema do
    use Absinthe.Schema

    query do
      field :books, list_of(:book)
    end

    mutation do
      field :change_name, :book do
        arg :id, non_null(:id)
        arg :name, non_null(:string)
      end
    end

    object :book do
      field :id, :id
      field :name, :string
      field :categories, list_of(:category)
    end

    subscription do
      field :new_book, :book
    end

    object :category do
      field :name
    end

  end

  @pre_pipeline [Phase.Parse, Phase.Blueprint]

  @nameless_query """
  { books { name } }
  """

  @query """
  query Q($cats: Boolean!) {
    books {
      name
      categories @include(if: $cats) {
        ... CategoryName
      }
    }
  }
  query BooksOnly {
    books { ... BookName }
  }
  mutation ChangeName($id: ID!, $name: String!) {
    changeName(id: $id, name: $name) {
      id
      name
    }
  }
  subscription NewBooks {
    newBook {
      id
    }
  }
  fragment BookName on Book {
    name
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

    it "sets the query operation schema node" do
      {:ok, result} = input(@query)
      ~w(Q BooksOnly)
      |> Enum.each(fn
        name ->
          node = op(result, name)
        assert %Absinthe.Type.Object{__reference__: %{identifier: :query}} = node.schema_node
      end)
    end

    it "sets the non-named query operation schema node" do
      {:ok, result} = input(@nameless_query)
      node = op(result, nil)
      assert %Absinthe.Type.Object{__reference__: %{identifier: :query}} = node.schema_node
    end

    it "sets the mutation schema node" do
      {:ok, result} = input(@query)
      node = op(result, "ChangeName")
      assert %Absinthe.Type.Object{__reference__: %{identifier: :mutation}} = node.schema_node
    end

    it "sets the subscription schema node" do
      {:ok, result} = input(@query)
      node = op(result, "NewBooks")
      assert %Absinthe.Type.Object{__reference__: %{identifier: :subscription}} = node.schema_node
    end

    it "sets the named fragment schema node" do
      {:ok, result} = input(@query)
      node = frag(result, "BookName")
      assert %Absinthe.Type.Object{__reference__: %{identifier: :book}} = node.schema_node
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

  def frag(blueprint, name) do
    Blueprint.find(blueprint.fragments, fn
      %Blueprint.Document.Fragment.Named{name: ^name} ->
        true
      _ ->
        false
    end)
  end

  def op(blueprint, name) do
    Blueprint.find(blueprint.operations, fn
      %Blueprint.Document.Operation{name: ^name} ->
        true
      _ ->
        false
    end)
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
