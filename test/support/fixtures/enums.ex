defmodule Absinthe.Fixtures.Enums do
  defmodule TestSchemaValueDescriptionKeyword do
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

    enum :description_keyword_argument do
      value :normal_string, description: "string"
      value :local_function_call, description: test_function("red")

      value :function_call_using_absolute_path_to_current_module,
        description:
          Absinthe.Fixtures.Enums.TestSchemaValueDescriptionKeyword.test_function("red")

      value :standard_library_function, description: String.replace("red", "e", "a")
      value :function_in_nested_module, description: NestedModule.nested_function("hello")

      value :external_module_function_call,
        description: Absinthe.Fixtures.FunctionEvaluationHelpers.external_function("hello")

      value :module_attribute_string_concat, description: "hello " <> @module_attribute
      value :interpolation_of_module_attribute, description: "hello #{@module_attribute}"
    end
  end

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

    enum :normal_string, description: "string" do
    end

    enum :local_function_call, description: test_function("red") do
    end

    enum :function_call_using_absolute_path_to_current_module,
      description: Absinthe.Fixtures.Enums.TestSchemaDescriptionKeyword.test_function("red") do
    end

    enum :standard_library_function, description: String.replace("red", "e", "a") do
    end

    enum :function_in_nested_module, description: NestedModule.nested_function("hello") do
    end

    enum :external_module_function_call,
      description: Absinthe.Fixtures.FunctionEvaluationHelpers.external_function("hello") do
    end

    enum :module_attribute_string_concat, description: "hello " <> @module_attribute do
    end

    enum :interpolation_of_module_attribute, description: "hello #{@module_attribute}" do
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
    enum :normal_string do
    end

    # These tests do not work as test_function is not available at compile time, and the
    # expression for the @desc attribute is evaluated at compile time. There is nothing we can
    # really do about it

    # @desc test_function("red")
    # enum :local_function_call do
    # end

    # @desc Absinthe.Fixtures.Enums.TestSchemaEnumAttribute.test_function("red")
    # enum :function_call_using_absolute_path_to_current_module do
    # end

    @desc String.replace("red", "e", "a")
    enum :standard_library_function do
    end

    @desc NestedModule.nested_function("hello")
    enum :function_in_nested_module do
    end

    @desc Absinthe.Fixtures.FunctionEvaluationHelpers.external_function("hello")
    enum :external_module_function_call do
    end

    @desc "hello " <> @module_attribute
    enum :module_attribute_string_concat do
    end

    @desc "hello #{@module_attribute}"
    enum :interpolation_of_module_attribute do
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

    enum :normal_string do
      description "string"
    end

    enum :local_function_call do
      description test_function("red")
    end

    enum :function_call_using_absolute_path_to_current_module do
      description Absinthe.Fixtures.Enums.TestSchemaDescriptionMacro.test_function("red")
    end

    enum :standard_library_function do
      description String.replace("red", "e", "a")
    end

    enum :function_in_nested_module do
      description NestedModule.nested_function("hello")
    end

    enum :external_module_function_call do
      description Absinthe.Fixtures.FunctionEvaluationHelpers.external_function("hello")
    end

    enum :module_attribute_string_concat do
      description "hello " <> @module_attribute
    end

    enum :interpolation_of_module_attribute do
      description "hello #{@module_attribute}"
    end
  end
end
