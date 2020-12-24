defmodule Absinthe.Type.UnionTest do
  use Absinthe.Case, async: true

  alias Absinthe.Type
  alias Absinthe.Fixtures.Union

  defmodule TestSchema do
    use Absinthe.Schema

    query do
      # Query type must exist
    end

    object :person do
      description "A person"

      field :name, :string
      field :age, :integer
    end

    object :business do
      description "A business"

      field :name, :string
      field :employee_count, :integer
    end

    union :search_result do
      description "A search result"

      types [:person, :business]

      resolve_type fn
        %{age: _}, _ ->
          :person

        %{employee_count: _}, _ ->
          :business
      end
    end

    object :foo do
      field :name, :string

      is_type_of fn
        %{name: _} -> true
        _ -> false
      end
    end

    union :other_result do
      types [:foo]
    end
  end

  describe "union" do
    test "can be defined" do
      obj = TestSchema.__absinthe_type__(:search_result)

      assert %Absinthe.Type.Union{
               name: "SearchResult",
               description: "A search result",
               types: [:business, :person]
             } = obj

      assert Absinthe.Type.function(obj, :resolve_type)
    end

    test "can resolve the type of an object using resolve_type" do
      obj = TestSchema.__absinthe_type__(:search_result)

      assert %Type.Object{name: "Person"} =
               Type.Union.resolve_type(obj, %{age: 12}, %{schema: TestSchema})

      assert %Type.Object{name: "Business"} =
               Type.Union.resolve_type(obj, %{employee_count: 12}, %{schema: TestSchema})
    end

    test "can resolve the type of an object using is_type_of" do
      obj = TestSchema.__absinthe_type__(:other_result)

      assert %Type.Object{name: "Foo"} =
               Type.Union.resolve_type(obj, %{name: "asdf"}, %{schema: TestSchema})
    end
  end

  describe "union keyword description evaluation" do
    Absinthe.Fixtures.FunctionEvaluationHelpers.function_evaluation_test_params()
    |> Enum.each(fn %{
                      test_label: test_label,
                      expected_value: expected_value
                    } ->
      test "for #{test_label} (evaluates description to '#{expected_value}')" do
        type = Union.TestSchemaDescriptionKeyword.__absinthe_type__(unquote(test_label))
        assert type.description == unquote(expected_value)
      end
    end)
  end

  describe "union description attribute evaluation" do
    Absinthe.Fixtures.FunctionEvaluationHelpers.function_evaluation_test_params()
    |> Absinthe.Fixtures.FunctionEvaluationHelpers.filter_test_params_for_description_attribute()
    |> Enum.each(fn %{
                      test_label: test_label,
                      expected_value: expected_value
                    } ->
      test "for #{test_label} (evaluates description to '#{expected_value}')" do
        type = Union.TestSchemaDescriptionAttribute.__absinthe_type__(unquote(test_label))

        assert type.description == unquote(expected_value)
      end
    end)
  end

  describe "union description macro evaluation" do
    Absinthe.Fixtures.FunctionEvaluationHelpers.function_evaluation_test_params()
    |> Enum.each(fn %{
                      test_label: test_label,
                      expected_value: expected_value
                    } ->
      test "for #{test_label} (evaluates description to '#{expected_value}')" do
        type = Union.TestSchemaDescriptionMacro.__absinthe_type__(unquote(test_label))
        assert type.description == unquote(expected_value)
      end
    end)
  end
end
