defmodule Absinthe.Phase.Document.SchemaTest do
  use Absinthe.Case, async: true

  alias Absinthe.{Blueprint, Phase, Pipeline, Type}

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

      field :add_review, :review do
        arg :info, non_null(:input_review)
      end
    end

    object :book do
      field :id, :id
      field :name, :string
      field :categories, list_of(:category)
      field :reviews, list_of(:review)
    end

    subscription do
      field :new_book, :book
    end

    object :category do
      field(:name)
    end

    object :review do
      field :stars, :integer
      field :text, :string
    end

    input_object :input_review do
      field :stars, non_null(:integer)
      field :text, :string
    end
  end

  @pre_pipeline Pipeline.for_document(Schema) |> Pipeline.before(Phase.Schema)

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
  mutation ModifyBook($id: ID!, $name: String!) {
    changeName(id: $id, name: $name) {
      id
      name
    }
    addReview(id: $id, info: {stars: 4})
  }
  subscription NewBooks {
    newBook {
      ... on Book {
        id
      }
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
    test "sets the root schema field" do
      {:ok, result} = input(@query)
      assert result.schema == Schema
    end

    test "sets the query operation schema node" do
      {:ok, result} = input(@query)

      ~w(Q BooksOnly)
      |> Enum.each(fn name ->
        node = op(result, name)
        assert %Type.Object{__reference__: %{identifier: :query}} = node.schema_node
      end)
    end

    test "sets the non-named query operation schema node" do
      {:ok, result} = input(@nameless_query)
      node = op(result, nil)
      assert %Type.Object{__reference__: %{identifier: :query}} = node.schema_node
    end

    test "sets the mutation schema node" do
      {:ok, result} = input(@query)
      node = op(result, "ModifyBook")
      assert %Type.Object{__reference__: %{identifier: :mutation}} = node.schema_node
    end

    test "sets the subscription schema node" do
      {:ok, result} = input(@query)
      node = op(result, "NewBooks")
      assert %Type.Object{__reference__: %{identifier: :subscription}} = node.schema_node
    end

    test "sets the named fragment schema node" do
      {:ok, result} = input(@query)
      node = frag(result, "BookName")
      assert %Type.Object{__reference__: %{identifier: :book}} = node.schema_node
    end

    test "sets the schema node for a named fragment field" do
      {:ok, result} = input(@query)
      fragment = frag(result, "BookName")
      node = field(fragment, "name")
      assert %Type.Field{__reference__: %{identifier: :name}} = node.schema_node
    end

    test "sets the inline fragment schema node" do
      {:ok, result} = input(@query)
      node = first_inline_frag(result)
      assert %Type.Object{__reference__: %{identifier: :book}} = node.schema_node
    end

    test "sets the schema node for an inline fragment" do
      {:ok, result} = input(@query)
      fragment = first_inline_frag(result)
      node = field(fragment, "id")
      assert %Type.Field{__reference__: %{identifier: :id}} = node.schema_node
    end

    test "sets an operation field schema node" do
      {:ok, result} = input(@query)
      operation = op(result, "BooksOnly")
      node = field(operation, "books")
      assert %Type.Field{__reference__: %{identifier: :books}} = node.schema_node
    end

    test "sets an field schema node inside another field" do
      {:ok, result} = input(@query)
      operation = op(result, "Q")
      books = field(operation, "books")
      node = field(books, "name")
      assert %Type.Field{__reference__: %{identifier: :name}} = node.schema_node
    end

    test "sets an operation field schema node supporting an adapter" do
      {:ok, result} = input(@query)
      node = named(result, Blueprint.Document.Field, "changeName")
      assert %Type.Field{__reference__: %{identifier: :change_name}} = node.schema_node
    end

    test "sets directive schema nodes" do
      {:ok, result} = input(@query)
      directive = named(result, Blueprint.Directive, "include")
      assert %Type.Directive{name: "include"} = directive.schema_node
    end

    test "sets field argument schema nodes" do
      {:ok, result} = input(@query)
      operation = op(result, "ModifyBook")
      f = field(operation, "changeName")
      node = named(f, Blueprint.Input.Argument, "id")
      assert %Type.Argument{__reference__: %{identifier: :id}} = node.schema_node
    end

    test "sets field argument schema nodes supporting input objects" do
      {:ok, result} = input(@query)
      operation = op(result, "ModifyBook")
      f = field(operation, "addReview")
      top_node = named(f, Blueprint.Input.Argument, "info")
      assert %Type.Argument{__reference__: %{identifier: :info}} = top_node.schema_node
      node = top_node.input_value.normalized.fields |> List.first()
      assert %Type.Field{__reference__: %{identifier: :stars}} = node.schema_node

      assert %Type.NonNull{of_type: %Type.Scalar{__reference__: %{identifier: :integer}}} =
               node.input_value.schema_node
    end

    test "sets directive argument schema nodes" do
      {:ok, result} = input(@query)
      directive = named(result, Blueprint.Directive, "include")
      node = named(directive, Blueprint.Input.Argument, "if")
      assert %Type.Argument{__reference__: %{identifier: :if}} = node.schema_node
    end
  end

  defp first_inline_frag(blueprint) do
    Blueprint.find(blueprint.operations, fn
      %Blueprint.Document.Fragment.Inline{} ->
        true

      _ ->
        false
    end)
  end

  defp frag(blueprint, name) do
    Blueprint.find(blueprint.fragments, fn
      %Blueprint.Document.Fragment.Named{name: ^name} ->
        true

      _ ->
        false
    end)
  end

  defp op(blueprint, name) do
    Blueprint.find(blueprint.operations, fn
      %Blueprint.Document.Operation{name: ^name} ->
        true

      _ ->
        false
    end)
  end

  defp field(scope, name) do
    Blueprint.find(scope.selections, fn
      %Blueprint.Document.Field{name: ^name} ->
        true

      _ ->
        false
    end)
  end

  defp named(scope, mod, name) do
    Blueprint.find(scope, fn
      %{__struct__: ^mod, name: ^name} ->
        true

      _ ->
        false
    end)
  end

  defp input(query) do
    blueprint(query)
    |> Phase.Schema.run(schema: Schema)
  end

  defp blueprint(query) do
    {:ok, blueprint, _} = Pipeline.run(query, @pre_pipeline)
    blueprint
  end
end
