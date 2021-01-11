defmodule Absinthe.Fixtures.InputObject do
  defmodule TestSchemaDescriptionKeyword do
    use Absinthe.Schema
    @module_attribute "goodbye"

    defmodule NestedModule do
      def nested_function(arg1) do
        arg1
      end
    end

    query do
    end

    input_object :normal_string, description: "string" do
    end

    input_object :local_function_call, description: test_function("red") do
    end

    input_object :function_call_using_absolute_path_to_current_module,
      description: Absinthe.Fixtures.InputObject.TestSchemaDescriptionKeyword.test_function("red") do
    end

    input_object :standard_library_function, description: String.replace("red", "e", "a") do
    end

    input_object :function_in_nested_module, description: NestedModule.nested_function("hello") do
    end

    input_object :external_module_function_call,
      description: Absinthe.Fixtures.FunctionEvaluationHelpers.external_function("hello") do
    end

    input_object :module_attribute_string_concat, description: "hello " <> @module_attribute do
    end

    input_object :interpolation_of_module_attribute, description: "hello #{@module_attribute}" do
    end

    def test_function(arg1) do
      arg1
    end
  end

  defmodule TestSchemaDescriptionAttribute do
    use Absinthe.Schema
    @module_attribute "goodbye"

    defmodule NestedModule do
      def nested_function(arg1) do
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

    # @desc Absinthe.Fixtures.InputObject.TestSchemaAttribute.test_function("red")
    # input_object :function_call_using_absolute_path_to_current_module do
    # end

    @desc String.replace("red", "e", "a")
    input_object :standard_library_function do
    end

    @desc NestedModule.nested_function("hello")
    input_object :function_in_nested_module do
    end

    @desc Absinthe.Fixtures.FunctionEvaluationHelpers.external_function("hello")
    input_object :external_module_function_call do
    end

    @desc "hello " <> @module_attribute
    input_object :module_attribute_string_concat do
    end

    @desc "hello #{@module_attribute}"
    input_object :interpolation_of_module_attribute do
    end
  end

  defmodule TestSchemaDescriptionMacro do
    use Absinthe.Schema
    @module_attribute "goodbye"

    defmodule NestedModule do
      def nested_function(arg1) do
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

    input_object :function_call_using_absolute_path_to_current_module do
      description Absinthe.Fixtures.InputObject.TestSchemaDescriptionMacro.test_function("red")
    end

    input_object :standard_library_function do
      description String.replace("red", "e", "a")
    end

    input_object :function_in_nested_module do
      description NestedModule.nested_function("hello")
    end

    input_object :external_module_function_call do
      description Absinthe.Fixtures.FunctionEvaluationHelpers.external_function("hello")
    end

    input_object :module_attribute_string_concat do
      description "hello " <> @module_attribute
    end

    input_object :interpolation_of_module_attribute do
      description "hello #{@module_attribute}"
    end
  end

  defmodule TestSchemaFieldsAndArgsDescription do
    use Absinthe.Schema
    @module_attribute "goodbye"

    defmodule NestedModule do
      def nested_function(arg1) do
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

      field :function_call_using_absolute_path_to_current_module, :string,
        description:
          Absinthe.Fixtures.InputObject.TestSchemaFieldsAndArgsDescription.test_function("red")

      field :standard_library_function, :string, description: String.replace("red", "e", "a")

      field :function_in_nested_module, :string,
        description: NestedModule.nested_function("hello")

      field :external_module_function_call, :string,
        description: Absinthe.Fixtures.FunctionEvaluationHelpers.external_function("hello")

      field :module_attribute_string_concat, :string, description: "hello " <> @module_attribute
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

      # @desc Absinthe.Fixtures.InputObject.TestSchemaFieldsAndArgsDescription.test_function(
      #         "red"
      #       )
      # field :function_call_using_absolute_path_to_current_module, :string

      @desc String.replace("red", "e", "a")
      field :standard_library_function, :string

      @desc NestedModule.nested_function("hello")
      field :function_in_nested_module, :string

      @desc Absinthe.Fixtures.FunctionEvaluationHelpers.external_function("hello")
      field :external_module_function_call, :string

      @desc "hello " <> @module_attribute
      field :module_attribute_string_concat, :string

      @desc "hello #{@module_attribute}"
      field :interpolation_of_module_attribute, :string
    end

    input_object :field_description_macro do
      field :normal_string, :string do
        description "string"
      end

      field :local_function_call, :string do
        description test_function("red")
      end

      field :function_call_using_absolute_path_to_current_module, :string do
        description Absinthe.Fixtures.InputObject.TestSchemaFieldsAndArgsDescription.test_function(
                      "red"
                    )
      end

      field :standard_library_function, :string do
        description String.replace("red", "e", "a")
      end

      field :function_in_nested_module, :string do
        description NestedModule.nested_function("hello")
      end

      field :external_module_function_call, :string do
        description Absinthe.Fixtures.FunctionEvaluationHelpers.external_function("hello")
      end

      field :module_attribute_string_concat, :string do
        description "hello " <> @module_attribute
      end

      field :interpolation_of_module_attribute, :string do
        description "hello #{@module_attribute}"
      end
    end

    input_object :field_default_value do
      field :normal_string, :string, default_value: "string"
      field :local_function_call, :string, default_value: test_function("red")

      field :function_call_using_absolute_path_to_current_module, :string,
        default_value:
          Absinthe.Fixtures.InputObject.TestSchemaFieldsAndArgsDescription.test_function("red")

      field :standard_library_function, :string, default_value: String.replace("red", "e", "a")

      field :function_in_nested_module, :string,
        default_value: NestedModule.nested_function("hello")

      field :external_module_function_call, :string,
        default_value: Absinthe.Fixtures.FunctionEvaluationHelpers.external_function("hello")

      field :module_attribute_string_concat, :string, default_value: "hello " <> @module_attribute

      field :interpolation_of_module_attribute, :string,
        default_value: "hello #{@module_attribute}"
    end
  end
end
