defmodule Absinthe.Fixtures.Union do
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

    union :normal_string, description: "string" do
    end

    union :local_function_call, description: test_function("red") do
    end

    union :function_call_using_absolute_path_to_current_module,
      description: Absinthe.Fixtures.Union.TestSchemaDescriptionKeyword.test_function("red") do
    end

    union :standard_library_function, description: String.replace("red", "e", "a") do
    end

    union :function_in_nested_module, description: NestedModule.nested_function("hello") do
    end

    union :external_module_function_call,
      description: Absinthe.Fixtures.FunctionEvaluationHelpers.external_function("hello") do
    end

    union :module_attribute_string_concat, description: "hello " <> @module_attribute do
    end

    union :interpolation_of_module_attribute, description: "hello #{@module_attribute}" do
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
    union :normal_string do
    end

    # These tests do not work as test_function is not available at compile time, and the
    # expression for the @desc attribute is evaluated at compile time. There is nothing we can
    # really do about it

    # @desc test_function("red")
    # union :local_function_call do

    # end

    # @desc Absinthe.Fixtures.Union.TestSchemaEnumAttribute.test_function("red")
    # union :function_call_using_absolute_path_to_current_module do

    # end

    @desc String.replace("red", "e", "a")
    union :standard_library_function do
    end

    @desc NestedModule.nested_function("hello")
    union :function_in_nested_module do
    end

    @desc Absinthe.Fixtures.FunctionEvaluationHelpers.external_function("hello")
    union :external_module_function_call do
    end

    @desc "hello " <> @module_attribute
    union :module_attribute_string_concat do
    end

    @desc "hello #{@module_attribute}"
    union :interpolation_of_module_attribute do
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

    union :normal_string do
      description "string"
    end

    union :local_function_call do
      description test_function("red")
    end

    union :function_call_using_absolute_path_to_current_module do
      description Absinthe.Fixtures.Union.TestSchemaDescriptionMacro.test_function("red")
    end

    union :standard_library_function do
      description String.replace("red", "e", "a")
    end

    union :function_in_nested_module do
      description NestedModule.nested_function("hello")
    end

    union :external_module_function_call do
      description Absinthe.Fixtures.FunctionEvaluationHelpers.external_function("hello")
    end

    union :module_attribute_string_concat do
      description "hello " <> @module_attribute
    end

    union :interpolation_of_module_attribute do
      description "hello #{@module_attribute}"
    end
  end
end
