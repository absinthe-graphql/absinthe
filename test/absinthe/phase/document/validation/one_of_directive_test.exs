defmodule Absinthe.Phase.Document.Validation.OneOfDirectiveTest do
  use Absinthe.Case, async: true

  defmodule Schema do
    use Absinthe.Schema

    input_object :valid_input do
      directive :one_of
      field :id, :id
      field :name, :string
    end

    query do
      field :valid, :boolean do
        arg :input, :valid_input
        resolve fn _, _ -> {:ok, true} end
      end
    end
  end

  @query "query NamedQuery($input: ValidInput!) { valid(input: $input) }"
  @message ~s[The Input Type "ValidInput" has the @oneOf directive. It must have exactly one non-null field.]

  describe "run/2" do
    test "without arg" do
      assert {:ok, %{data: _} = result} = Absinthe.run("query { valid }", Schema)
      refute result[:errors]
    end

    test "with one inline arg" do
      assert {:ok, %{data: _} = result} = Absinthe.run("query { valid(input: {id: 1}) }", Schema)
      refute result[:errors]
    end

    test "with both inline args but one is null" do
      query = "query { valid(input: {id: 1, name: null}) }"
      assert {:ok, %{data: _} = result} = Absinthe.run(query, Schema)
      refute result[:errors]
    end

    test "with one variable arg" do
      options = [variables: %{"input" => %{"id" => 1}}]
      assert {:ok, %{data: _} = result} = Absinthe.run(@query, Schema, options)
      refute result[:errors]
    end

    test "with both variable args but one is null" do
      options = [variables: %{"input" => %{"id" => 1, "name" => nil}}]
      assert {:ok, %{data: _} = result} = Absinthe.run(@query, Schema, options)
      refute result[:errors]
    end

    test "with both inline args" do
      query = ~s[query { valid(input: {id: 1, name: "a"}) }]
      assert {:ok, %{errors: [error]} = result} = Absinthe.run(query, Schema)
      assert %{locations: [%{column: 15, line: 1}], message: @message} = error
      refute result[:data]
    end

    test "with both inline args nil" do
      query = ~s[query { valid(input: {id: null, name: null}) }]
      assert {:ok, %{errors: [error]} = result} = Absinthe.run(query, Schema)
      assert %{locations: [%{column: 15, line: 1}], message: @message} = error
      refute result[:data]
    end

    test "with both variable args" do
      options = [variables: %{"input" => %{"id" => 1, "name" => "a"}}]
      assert {:ok, %{errors: [error]} = result} = Absinthe.run(@query, Schema, options)
      assert %{locations: [%{column: 47, line: 1}], message: @message} = error
      refute result[:data]
    end
  end
end
