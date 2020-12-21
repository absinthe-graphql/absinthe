defmodule Absinthe.Fixtures.Directive do
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

    directive :normal_string, description: "string" do
      on [:field]
    end

    directive :local_function_call, description: test_function("red") do
      on [:field]
    end

    directive :function_call_using_absolute_path_to_current_module,
      description: Absinthe.Fixtures.Directive.TestSchemaDescriptionKeyword.test_function("red") do
      on [:field]
    end

    directive :standard_library_function, description: String.replace("red", "e", "a") do
      on [:field]
    end

    directive :function_in_nested_module, description: NestedModule.nested_function("hello") do
      on [:field]
    end

    directive :external_module_function_call,
      description: Absinthe.Fixtures.FunctionEvaluationHelpers.external_function("hello") do
      on [:field]
    end

    directive :module_attribute_string_concat, description: "hello " <> @module_attribute do
      on [:field]
    end

    directive :interpolation_of_module_attribute, description: "hello #{@module_attribute}" do
      on [:field]
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
    directive :normal_string do
      on [:field]
    end

    # These tests do not work as test_function is not available at compile time, and the
    # expression for the @desc attribute is evaluated at compile time. There is nothing we can
    # really do about it

    # @desc test_function("red")
    # directive :local_function_call do
    #   on [:field]
    # end

    # @desc Absinthe.Fixtures.Directive.TestSchemaEnumAttribute.test_function("red")
    # directive :function_call_using_absolute_path_to_current_module do
    #   on [:field]
    # end

    @desc String.replace("red", "e", "a")
    directive :standard_library_function do
      on [:field]
    end

    @desc NestedModule.nested_function("hello")
    directive :function_in_nested_module do
      on [:field]
    end

    @desc Absinthe.Fixtures.FunctionEvaluationHelpers.external_function("hello")
    directive :external_module_function_call do
      on [:field]
    end

    @desc "hello " <> @module_attribute
    directive :module_attribute_string_concat do
      on [:field]
    end

    @desc "hello #{@module_attribute}"
    directive :interpolation_of_module_attribute do
      on [:field]
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

    directive :normal_string do
      on [:field]
      description "string"
    end

    directive :local_function_call do
      on [:field]
      description test_function("red")
    end

    directive :function_call_using_absolute_path_to_current_module do
      on [:field]
      description Absinthe.Fixtures.Directive.TestSchemaDescriptionMacro.test_function("red")
    end

    directive :standard_library_function do
      on [:field]
      description String.replace("red", "e", "a")
    end

    directive :function_in_nested_module do
      on [:field]
      description NestedModule.nested_function("hello")
    end

    directive :external_module_function_call do
      on [:field]
      description Absinthe.Fixtures.FunctionEvaluationHelpers.external_function("hello")
    end

    directive :module_attribute_string_concat do
      on [:field]
      description "hello " <> @module_attribute
    end

    directive :interpolation_of_module_attribute do
      on [:field]
      description "hello #{@module_attribute}"
    end
  end

  defmodule TestSchemaArgDescriptionKeyword do
    use Absinthe.Schema
    @module_attribute "goodbye"

    defmodule NestedModule do
      def nested_function(arg1) do
        arg1
      end
    end

    query do
    end

    directive :normal_string do
      arg :arg_example, :string, description: "string"
      on [:field]
    end

    directive :local_function_call do
      arg :arg_example, :string, description: test_function("red")
      on [:field]
    end

    directive :function_call_using_absolute_path_to_current_module do
      arg :arg_example, :string,
        description: Absinthe.Fixtures.Directive.TestSchemaDescriptionKeyword.test_function("red")

      on [:field]
    end

    directive :standard_library_function do
      arg :arg_example, :string, description: String.replace("red", "e", "a")
      on [:field]
    end

    directive :function_in_nested_module do
      arg :arg_example, :string, description: NestedModule.nested_function("hello")
      on [:field]
    end

    directive :external_module_function_call do
      arg :arg_example, :string,
        description: Absinthe.Fixtures.FunctionEvaluationHelpers.external_function("hello")

      on [:field]
    end

    directive :module_attribute_string_concat do
      arg :arg_example, :string, description: "hello " <> @module_attribute
      on [:field]
    end

    directive :interpolation_of_module_attribute do
      arg :arg_example, :string, description: "hello #{@module_attribute}"
      on [:field]
    end

    def test_function(arg1) do
      arg1
    end
  end
end
