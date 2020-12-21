defmodule Absinthe.Fixtures.Object do
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
      description:
        Absinthe.Fixtures.Object.TestSchemaDescriptionKeyword.test_function("red") do
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
end
