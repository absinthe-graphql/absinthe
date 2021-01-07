defmodule Absinthe.Type.InputObjectTest do
  use Absinthe.Case, async: true

  alias Absinthe.Fixtures.InputObject

  # Note: The arg description evaluation tests are in test/absinthe/type/query_test.exs

  defmodule Schema do
    use Absinthe.Schema

    query do
      # Query type must exist
    end

    @desc "A profile"
    input_object :profile do
      field :name, :string
      field :profile_picture, :string
    end
  end

  describe "input object types" do
    test "can be defined" do
      assert %Absinthe.Type.InputObject{name: "Profile", description: "A profile"} =
               Schema.__absinthe_type__(:profile)

      assert %{profile: "Profile"} = Schema.__absinthe_types__(:all)
    end

    test "can define fields" do
      obj = Schema.__absinthe_type__(:profile)
      assert %Absinthe.Type.Field{name: "name", type: :string} = obj.fields.name
    end
  end

  describe "input object keyword description evaluation" do
    Absinthe.Fixtures.FunctionEvaluationHelpers.function_evaluation_test_params()
    |> Enum.each(fn %{
                      test_label: test_label,
                      expected_value: expected_value
                    } ->
      test "for #{test_label} (evaluates description to '#{expected_value}')" do
        type = InputObject.TestSchemaDescriptionKeyword.__absinthe_type__(unquote(test_label))
        assert type.description == unquote(expected_value)
      end
    end)
  end

  describe "input_object description attribute evaluation" do
    Absinthe.Fixtures.FunctionEvaluationHelpers.function_evaluation_test_params()
    |> Absinthe.Fixtures.FunctionEvaluationHelpers.filter_test_params_for_description_attribute()
    |> Enum.each(fn %{
                      test_label: test_label,
                      expected_value: expected_value
                    } ->
      test "for #{test_label} (evaluates description to '#{expected_value}')" do
        type = InputObject.TestSchemaDescriptionAttribute.__absinthe_type__(unquote(test_label))
        assert type.description == unquote(expected_value)
      end
    end)
  end

  describe "input_object description macro evaluation" do
    Absinthe.Fixtures.FunctionEvaluationHelpers.function_evaluation_test_params()
    |> Enum.each(fn %{
                      test_label: test_label,
                      expected_value: expected_value
                    } ->
      test "for #{test_label} (evaluates description to '#{expected_value}')" do
        type = InputObject.TestSchemaDescriptionMacro.__absinthe_type__(unquote(test_label))
        assert type.description == unquote(expected_value)
      end
    end)
  end

  describe "input object field keyword description evaluation" do
    Absinthe.Fixtures.FunctionEvaluationHelpers.function_evaluation_test_params()
    |> Enum.each(fn %{
                      test_label: test_label,
                      expected_value: expected_value
                    } ->
      test "for #{test_label} (evaluates description to '#{expected_value}')" do
        type =
          InputObject.TestSchemaFieldsAndArgsDescription.__absinthe_type__(
            :description_keyword_argument
          )

        assert type.fields[unquote(test_label)].description == unquote(expected_value)
      end
    end)
  end

  describe "input object field attribute description evaluation" do
    Absinthe.Fixtures.FunctionEvaluationHelpers.function_evaluation_test_params()
    |> Absinthe.Fixtures.FunctionEvaluationHelpers.filter_test_params_for_description_attribute()
    |> Enum.each(fn %{
                      test_label: test_label,
                      expected_value: expected_value
                    } ->
      test "for #{test_label} (evaluates description to '#{expected_value}')" do
        type =
          InputObject.TestSchemaFieldsAndArgsDescription.__absinthe_type__(:description_attribute)

        assert type.fields[unquote(test_label)].description == unquote(expected_value)
      end
    end)
  end

  describe "input object field macro description evaluation" do
    Absinthe.Fixtures.FunctionEvaluationHelpers.function_evaluation_test_params()
    |> Enum.each(fn %{
                      test_label: test_label,
                      expected_value: expected_value
                    } ->
      test "for #{test_label} (evaluates description to '#{expected_value}')" do
        type =
          InputObject.TestSchemaFieldsAndArgsDescription.__absinthe_type__(
            :field_description_macro
          )

        assert type.fields[unquote(test_label)].description == unquote(expected_value)
      end
    end)
  end

  describe "input object field default_value evaluation" do
    Absinthe.Fixtures.FunctionEvaluationHelpers.function_evaluation_test_params()
    |> Enum.each(fn %{
                      test_label: test_label,
                      expected_value: expected_value
                    } ->
      test "for #{test_label} (evaluates default_value to '#{expected_value}')" do
        type =
          InputObject.TestSchemaFieldsAndArgsDescription.__absinthe_type__(:field_default_value)

        assert type.fields[unquote(test_label)].default_value == unquote(expected_value)
      end
    end)
  end
end
