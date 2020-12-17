defmodule Absinthe.Type.InputObjectTest do
  use Absinthe.Case, async: true

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

  defmodule TestSchemaInputObjectDescriptionKeyword do
    use Absinthe.Schema
    @module_attribute "goodbye"

    defmodule TestNestedModule do
      def nestedFunction(arg1) do
        arg1
      end
    end

    query do
    end

    input_object :normal_string, description: "string" do
    end

    input_object :local_function_call, description: test_function("red") do
    end

    input_object :function_call_using_absolute_path,
      description:
        Absinthe.Type.InputObjectTest.TestSchemaInputObjectDescriptionKeyword.test_function("red") do
    end

    input_object :standard_library_function_works, description: String.replace("red", "e", "a") do
    end

    input_object :function_nested_in_module, description: TestNestedModule.nestedFunction("hello") do
    end

    input_object :module_attribute, description: "hello " <> @module_attribute do
    end

    input_object :interpolation_of_module_attribute, description: "hello #{@module_attribute}" do
    end

    def test_function(arg1) do
      arg1
    end
  end

  defmodule TestSchemaInputObjectDescriptionAttribute do
    use Absinthe.Schema
    @module_attribute "goodbye"

    defmodule TestNestedModule do
      def nestedFunction(arg1) do
        arg1
      end
    end

    query do
    end

    def test_function(arg1) do
      arg1
    end

    @desc "string"
    input_object :normal_string do
    end

    # These tests do not work as test_function is not available at compile time, and the
    # expression for the @desc attribute is evaluated at compile time. There is nothing we can
    # really do about it

    # @desc test_function("red")
    # input_object :local_function_call do
    # end

    # @desc Absinthe.Type.InputObjectTest.TestSchemaInputObjectAttribute.test_function("red")
    # input_object :function_call_using_absolute_path do
    # end

    @desc String.replace("red", "e", "a")
    input_object :standard_library_function_works do
    end

    @desc TestNestedModule.nestedFunction("hello")
    input_object :function_nested_in_module do
    end

    @desc "hello " <> @module_attribute
    input_object :module_attribute do
    end

    @desc "hello #{@module_attribute}"
    input_object :interpolation_of_module_attribute do
    end
  end

  defmodule TestSchemaInputObjectDescriptionMacro do
    use Absinthe.Schema
    @module_attribute "goodbye"

    defmodule TestNestedModule do
      def nestedFunction(arg1) do
        arg1
      end
    end

    query do
    end

    def test_function(arg1) do
      arg1
    end

    input_object :normal_string do
      description "string"
    end

    input_object :local_function_call do
      description test_function("red")
    end

    input_object :function_call_using_absolute_path do
      description Absinthe.Type.InputObjectTest.TestSchemaInputObjectDescriptionMacro.test_function(
                    "red"
                  )
    end

    input_object :standard_library_function_works do
      description String.replace("red", "e", "a")
    end

    input_object :function_nested_in_module do
      description TestNestedModule.nestedFunction("hello")
    end

    input_object :module_attribute do
      description "hello " <> @module_attribute
    end

    input_object :interpolation_of_module_attribute do
      description "hello #{@module_attribute}"
    end
  end

  defmodule TestSchemaInputObjectFieldKeywordDescription do
    use Absinthe.Schema
    @module_attribute "goodbye"

    defmodule TestNestedModule do
      def nestedFunction(arg1) do
        arg1
      end
    end

    query do
    end

    def test_function(arg1) do
      arg1
    end

    input_object :description_keyword_argument do
      field :normal_string, :string, description: "string"
      field :local_function_call, :string, description: test_function("red")

      field :function_call_using_absolute_path, :string,
        description:
          Absinthe.Type.InputObjectTest.TestSchemaInputObjectFieldKeywordDescription.test_function(
            "red"
          )

      field :standard_library_function_works, :string,
        description: String.replace("red", "e", "a")

      field :function_nested_in_module, :string,
        description: TestNestedModule.nestedFunction("hello")

      field :module_attribute, :string, description: "hello " <> @module_attribute
      field :interpolation_of_module_attribute, :string, description: "hello #{@module_attribute}"
    end

    input_object :description_attribute do
      @desc "string"
      field :normal_string, :string

      # These tests do not work as test_function is not available at compile time, and the
      # expression for the @desc attribute is evaluated at compile time. There is nothing we can
      # really do about it

      # @desc test_function("red")
      # field :local_function_call, :string

      # @desc Absinthe.Type.InputObjectTest.TestSchemaInputObjectFieldKeywordDescription.test_function(
      #         "red"
      #       )
      # field :function_call_using_absolute_path, :string

      @desc String.replace("red", "e", "a")
      field :standard_library_function_works, :string

      @desc TestNestedModule.nestedFunction("hello")
      field :function_nested_in_module, :string

      @desc "hello " <> @module_attribute
      field :module_attribute, :string
      @desc "hello #{@module_attribute}"
      field :interpolation_of_module_attribute, :string
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
    Absinthe.FunctionEvaluationHelpers.function_evaluation_test_params()
    |> Enum.each(fn %{
                      test_label: test_label,
                      expected_description: expected_description
                    } ->
      test "for #{test_label}" do
        type = TestSchemaInputObjectDescriptionKeyword.__absinthe_type__(unquote(test_label))
        assert type.description == unquote(expected_description)
      end
    end)
  end

  describe "input_object description attribute evaluation" do
    Absinthe.FunctionEvaluationHelpers.function_evaluation_test_params()
    # These tests do not work as test_function is not available at compile time, and the
    # expression for the @desc attribute is evaluated at compile time. There is nothing we can
    # really do about it
    |> Enum.filter(fn %{test_label: test_label} ->
      test_label not in [:local_function_call, :function_call_using_absolute_path]
    end)
    |> Enum.each(fn %{
                      test_label: test_label,
                      expected_description: expected_description
                    } ->
      test "for #{test_label}" do
        type = TestSchemaInputObjectDescriptionAttribute.__absinthe_type__(unquote(test_label))
        assert type.description == unquote(expected_description)
      end
    end)
  end

  describe "input_object description macro evaluation" do
    Absinthe.FunctionEvaluationHelpers.function_evaluation_test_params()
    |> Enum.each(fn %{
                      test_label: test_label,
                      expected_description: expected_description
                    } ->
      test "for #{test_label}" do
        type = TestSchemaInputObjectDescriptionMacro.__absinthe_type__(unquote(test_label))
        assert type.description == unquote(expected_description)
      end
    end)
  end

  describe "input object field keyword description evaluation" do
    Absinthe.FunctionEvaluationHelpers.function_evaluation_test_params()
    |> Enum.each(fn %{
                      test_label: test_label,
                      expected_description: expected_description
                    } ->
      test "for #{test_label}" do
        type =
          TestSchemaInputObjectFieldKeywordDescription.__absinthe_type__(
            :description_keyword_argument
          )

        assert type.fields[unquote(test_label)].description == unquote(expected_description)
      end
    end)
  end

  describe "input object field attribute description evaluation" do
    Absinthe.FunctionEvaluationHelpers.function_evaluation_test_params()
    # These tests do not work as test_function is not available at compile time, and the
    # expression for the @desc attribute is evaluated at compile time. There is nothing we can
    # really do about it
    |> Enum.filter(fn %{test_label: test_label} ->
      test_label not in [:local_function_call, :function_call_using_absolute_path]
    end)
    |> Enum.each(fn %{
                      test_label: test_label,
                      expected_description: expected_description
                    } ->
      test "for #{test_label}" do
        type =
          TestSchemaInputObjectFieldKeywordDescription.__absinthe_type__(:description_attribute)

        assert type.fields[unquote(test_label)].description == unquote(expected_description)
      end
    end)
  end
end
