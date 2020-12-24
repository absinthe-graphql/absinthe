defmodule Absinthe.Fixtures.Scalar do
  defmodule Utils do
    def parse(value), do: value
    def serialize(value), do: value
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

    scalar :normal_string, description: "string" do
      parse &Utils.parse/1
      serialize &Utils.serialize/1
    end

    scalar :local_function_call, description: test_function("red") do
      parse &Utils.parse/1
      serialize &Utils.serialize/1
    end

    scalar :function_call_using_absolute_path_to_current_module,
      description: Absinthe.Fixtures.Scalar.TestSchemaDescriptionKeyword.test_function("red") do
      parse &Utils.parse/1
      serialize &Utils.serialize/1
    end

    scalar :standard_library_function, description: String.replace("red", "e", "a") do
      parse &Utils.parse/1
      serialize &Utils.serialize/1
    end

    scalar :function_in_nested_module, description: NestedModule.nested_function("hello") do
      parse &Utils.parse/1
      serialize &Utils.serialize/1
    end

    scalar :external_module_function_call,
      description: Absinthe.Fixtures.FunctionEvaluationHelpers.external_function("hello") do
      parse &Utils.parse/1
      serialize &Utils.serialize/1
    end

    scalar :module_attribute_string_concat, description: "hello " <> @module_attribute do
      parse &Utils.parse/1
      serialize &Utils.serialize/1
    end

    scalar :interpolation_of_module_attribute, description: "hello #{@module_attribute}" do
      parse &Utils.parse/1
      serialize &Utils.serialize/1
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
    scalar :normal_string do
      parse &Utils.parse/1
      serialize &Utils.serialize/1
    end

    # These tests do not work as test_function is not available at compile time, and the
    # expression for the @desc attribute is evaluated at compile time. There is nothing we can
    # really do about it

    # @desc test_function("red")
    # scalar :local_function_call do
    # parse &Utils.parse/1
    # serialize &Utils.serialize/1
    # end

    # @desc Absinthe.Fixtures.Scalar.TestSchemaEnumAttribute.test_function("red")
    # scalar :function_call_using_absolute_path_to_current_module do
    # parse &Utils.parse/1
    # serialize &Utils.serialize/1
    # end

    @desc String.replace("red", "e", "a")
    scalar :standard_library_function do
      parse &Utils.parse/1
      serialize &Utils.serialize/1
    end

    @desc NestedModule.nested_function("hello")
    scalar :function_in_nested_module do
      parse &Utils.parse/1
      serialize &Utils.serialize/1
    end

    @desc Absinthe.Fixtures.FunctionEvaluationHelpers.external_function("hello")
    scalar :external_module_function_call do
      parse &Utils.parse/1
      serialize &Utils.serialize/1
    end

    @desc "hello " <> @module_attribute
    scalar :module_attribute_string_concat do
      parse &Utils.parse/1
      serialize &Utils.serialize/1
    end

    @desc "hello #{@module_attribute}"
    scalar :interpolation_of_module_attribute do
      parse &Utils.parse/1
      serialize &Utils.serialize/1
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

    scalar :normal_string do
      parse &Utils.parse/1
      serialize &Utils.serialize/1
      description "string"
    end

    scalar :local_function_call do
      parse &Utils.parse/1
      serialize &Utils.serialize/1
      description test_function("red")
    end

    scalar :function_call_using_absolute_path_to_current_module do
      parse &Utils.parse/1
      serialize &Utils.serialize/1
      description Absinthe.Fixtures.Scalar.TestSchemaDescriptionMacro.test_function("red")
    end

    scalar :standard_library_function do
      parse &Utils.parse/1
      serialize &Utils.serialize/1
      description String.replace("red", "e", "a")
    end

    scalar :function_in_nested_module do
      parse &Utils.parse/1
      serialize &Utils.serialize/1
      description NestedModule.nested_function("hello")
    end

    scalar :external_module_function_call do
      parse &Utils.parse/1
      serialize &Utils.serialize/1
      description Absinthe.Fixtures.FunctionEvaluationHelpers.external_function("hello")
    end

    scalar :module_attribute_string_concat do
      parse &Utils.parse/1
      serialize &Utils.serialize/1
      description "hello " <> @module_attribute
    end

    scalar :interpolation_of_module_attribute do
      parse &Utils.parse/1
      serialize &Utils.serialize/1
      description "hello #{@module_attribute}"
    end
  end
end
