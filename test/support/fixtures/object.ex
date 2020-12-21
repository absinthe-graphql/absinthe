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

    object :normal_string, description: "string" do
    end

    object :local_function_call, description: test_function("red") do
    end

    object :function_call_using_absolute_path_to_current_module,
      description: Absinthe.Fixtures.Object.TestSchemaDescriptionKeyword.test_function("red") do
    end

    object :standard_library_function, description: String.replace("red", "e", "a") do
    end

    object :function_in_nested_module, description: NestedModule.nested_function("hello") do
    end

    object :external_module_function_call,
      description: Absinthe.Fixtures.FunctionEvaluationHelpers.external_function("hello") do
    end

    object :module_attribute_string_concat, description: "hello " <> @module_attribute do
    end

    object :interpolation_of_module_attribute, description: "hello #{@module_attribute}" do
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
    object :normal_string do
    end

    # These tests do not work as test_function is not available at compile time, and the
    # expression for the @desc attribute is evaluated at compile time. There is nothing we can
    # really do about it

    # @desc test_function("red")
    # object :local_function_call do
    # end

    # @desc Absinthe.Fixtures.Object.TestSchemaAttribute.test_function("red")
    # object :function_call_using_absolute_path_to_current_module do
    # end

    @desc String.replace("red", "e", "a")
    object :standard_library_function do
    end

    @desc NestedModule.nested_function("hello")
    object :function_in_nested_module do
    end

    @desc Absinthe.Fixtures.FunctionEvaluationHelpers.external_function("hello")
    object :external_module_function_call do
    end

    @desc "hello " <> @module_attribute
    object :module_attribute_string_concat do
    end

    @desc "hello #{@module_attribute}"
    object :interpolation_of_module_attribute do
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

    object :normal_string do
      description "string"
    end

    object :local_function_call do
      description test_function("red")
    end

    object :function_call_using_absolute_path_to_current_module do
      description Absinthe.Fixtures.Object.TestSchemaDescriptionMacro.test_function("red")
    end

    object :standard_library_function do
      description String.replace("red", "e", "a")
    end

    object :function_in_nested_module do
      description NestedModule.nested_function("hello")
    end

    object :external_module_function_call do
      description Absinthe.Fixtures.FunctionEvaluationHelpers.external_function("hello")
    end

    object :module_attribute_string_concat do
      description "hello " <> @module_attribute
    end

    object :interpolation_of_module_attribute do
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

    object :description_keyword_argument do
      field :normal_string, :string, description: "string"
      field :local_function_call, :string, description: test_function("red")

      field :function_call_using_absolute_path_to_current_module, :string,
        description:
          Absinthe.Fixtures.Object.TestSchemaFieldsAndArgsDescription.test_function("red")

      field :standard_library_function, :string, description: String.replace("red", "e", "a")

      field :function_in_nested_module, :string,
        description: NestedModule.nested_function("hello")

      field :external_module_function_call, :string,
        description: Absinthe.Fixtures.FunctionEvaluationHelpers.external_function("hello")

      field :module_attribute_string_concat, :string, description: "hello " <> @module_attribute
      field :interpolation_of_module_attribute, :string, description: "hello #{@module_attribute}"
    end

    object :description_attribute do
      @desc "string"
      field :normal_string, :string

      # These tests do not work as test_function is not available at compile time, and the
      # expression for the @desc attribute is evaluated at compile time. There is nothing we can
      # really do about it

      # @desc test_function("red")
      # field :local_function_call, :string

      # @desc Absinthe.Fixtures.Object.TestSchemaFieldsAndArgsDescription.test_function(
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

    object :field_description_macro do
      field :normal_string, :string do
        description "string"
      end

      field :local_function_call, :string do
        description test_function("red")
      end

      field :function_call_using_absolute_path_to_current_module, :string do
        description Absinthe.Fixtures.Object.TestSchemaFieldsAndArgsDescription.test_function(
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
  end
end
