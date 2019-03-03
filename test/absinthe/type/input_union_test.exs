defmodule Absinthe.Type.InputUnionTest do
  use Absinthe.Case, async: true

  alias Absinthe.Type

  defmodule TestSchema do
    use Absinthe.Schema

    query do
      # Query type must exist
    end

    input_object :person do
      description "A person"

      field :name, :string
      field :age, :integer
    end

    input_object :business do
      description "A business"

      field :name, :string
      field :employee_count, :integer
    end

    input_union :search_query do
      description "A search query"

      types [:person, :business]

      resolve_type fn
        %{age: _}, _ ->
          :person

        %{employee_count: _}, _ ->
          :business
      end
    end

    input_object :foo do
      field :name, :string

      is_type_of fn
        %{name: _} -> true
        _ -> false
      end
    end

    input_union :other_query do
      types [:foo]
    end
  end

  describe "union" do
    test "can be defined" do
      obj = TestSchema.__absinthe_type__(:search_query)

      assert %Absinthe.Type.InputUnion{
               name: "SearchQuery",
               description: "A search query",
               types: [:person, :business]
             } = obj

      assert obj.resolve_type
    end

    test "can resolve the type of an object using resolve_type" do
      obj = TestSchema.__absinthe_type__(:search_query)

      assert %Type.InputObject{name: "Person"} =
               Type.InputUnion.resolve_type(obj, %{age: 12}, %{schema: TestSchema})

      assert %Type.InputObject{name: "Business"} =
               Type.InputUnion.resolve_type(obj, %{employee_count: 12}, %{schema: TestSchema})
    end

    test "can resolve the type of an object using is_type_of" do
      obj = TestSchema.__absinthe_type__(:other_query)

      assert %Type.InputObject{name: "Foo"} =
               Type.InputUnion.resolve_type(obj, %{name: "asdf"}, %{schema: TestSchema})
    end
  end
end
