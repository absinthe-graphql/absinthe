defmodule Absinthe.Type.ObjectTest do
  use Absinthe.Case, async: true

  alias Absinthe.Fixtures.Object

  defmodule Schema do
    use Absinthe.Schema

    query do
      # Must exist
    end

    @desc "A person"
    object :person do
      description "A person"

      field :name, :string

      field :profile_picture, :string do
        arg :width, :integer
        arg :height, :integer
      end
    end
  end

  describe "object types" do
    test "can be defined" do
      assert %Absinthe.Type.Object{name: "Person", description: "A person"} =
               Schema.__absinthe_type__(:person)

      assert %{person: "Person"} = Schema.__absinthe_types__(:all)
    end

    test "can define fields" do
      obj = Schema.__absinthe_type__(:person)
      assert %Absinthe.Type.Field{name: "name", type: :string} = obj.fields.name
    end

    test "can define field arguments" do
      field = Schema.__absinthe_type__(:person).fields.profile_picture
      assert %Absinthe.Type.Argument{name: "width", type: :integer} = field.args.width
      assert %Absinthe.Type.Argument{name: "height", type: :integer} = field.args.height
    end
  end

  describe "object keyword description evaluation" do
    Absinthe.Fixtures.FunctionEvaluationHelpers.function_evaluation_test_params()
    |> Enum.each(fn %{
                      test_label: test_label,
                      expected_value: expected_value
                    } ->
      test "for #{test_label} (evaluates description to '#{expected_value}')" do
        type = Object.TestSchemaDescriptionKeyword.__absinthe_type__(unquote(test_label))
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
        type = Object.TestSchemaDescriptionAttribute.__absinthe_type__(unquote(test_label))
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
        type = Object.TestSchemaDescriptionMacro.__absinthe_type__(unquote(test_label))
        assert type.description == unquote(expected_value)
      end
    end)
  end

  describe "object field keyword description evaluation" do
    Absinthe.Fixtures.FunctionEvaluationHelpers.function_evaluation_test_params()
    |> Enum.each(fn %{
                      test_label: test_label,
                      expected_value: expected_value
                    } ->
      test "for #{test_label} (evaluates description to '#{expected_value}')" do
        type =
          Object.TestSchemaFieldsAndArgsDescription.__absinthe_type__(
            :description_keyword_argument
          )

        assert type.fields[unquote(test_label)].description == unquote(expected_value)
      end
    end)
  end

  describe "object field attribute description evaluation" do
    Absinthe.Fixtures.FunctionEvaluationHelpers.function_evaluation_test_params()
    |> Absinthe.Fixtures.FunctionEvaluationHelpers.filter_test_params_for_description_attribute()
    |> Enum.each(fn %{
                      test_label: test_label,
                      expected_value: expected_value
                    } ->
      test "for #{test_label} (evaluates description to '#{expected_value}')" do
        type = Object.TestSchemaFieldsAndArgsDescription.__absinthe_type__(:description_attribute)

        assert type.fields[unquote(test_label)].description == unquote(expected_value)
      end
    end)
  end

  describe "object field macro description evaluation" do
    Absinthe.Fixtures.FunctionEvaluationHelpers.function_evaluation_test_params()
    |> Enum.each(fn %{
                      test_label: test_label,
                      expected_value: expected_value
                    } ->
      test "for #{test_label} (evaluates description to '#{expected_value}')" do
        type =
          Object.TestSchemaFieldsAndArgsDescription.__absinthe_type__(:field_description_macro)

        assert type.fields[unquote(test_label)].description == unquote(expected_value)
      end
    end)
  end
end
