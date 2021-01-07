defmodule Absinthe.Fixtures.Query do
  defmodule TestSchemaFieldArgDescription do
    use Absinthe.Schema
    @module_attribute "goodbye"

    defmodule NestedModule do
      def nested_function(arg1) do
        arg1
      end
    end

    def test_function(arg1) do
      arg1
    end

    query do
      field :normal_string, :string do
        arg :arg_example, :string, description: "string"
      end

      field :local_function_call, :string do
        arg :arg_example, :string, description: test_function("red")
      end

      field :function_call_using_absolute_path_to_current_module, :string do
        arg :arg_example, :string,
          description: Absinthe.Fixtures.Query.TestSchemaFieldArgDescription.test_function("red")
      end

      field :standard_library_function, :string do
        arg :arg_example, :string, description: String.replace("red", "e", "a")
      end

      field :function_in_nested_module, :string do
        arg :arg_example, :string, description: NestedModule.nested_function("hello")
      end

      field :external_module_function_call, :string do
        arg :arg_example, :string,
          description: Absinthe.Fixtures.FunctionEvaluationHelpers.external_function("hello")
      end

      field :module_attribute_string_concat, :string do
        arg :arg_example, :string, description: "hello " <> @module_attribute
      end

      field :interpolation_of_module_attribute, :string do
        arg :arg_example, :string, description: "hello #{@module_attribute}"
      end
    end
  end

  defmodule TestSchemaFieldArgDefaultValue do
    use Absinthe.Schema
    @module_attribute "goodbye"

    defmodule NestedModule do
      def nested_function(arg1) do
        arg1
      end
    end

    def test_function(arg1) do
      arg1
    end

    query do
      field :normal_string, :string do
        arg :arg_example, :string, default_value: "string"
      end

      field :local_function_call, :string do
        arg :arg_example, :string, default_value: test_function("red")
      end

      field :function_call_using_absolute_path_to_current_module, :string do
        arg :arg_example, :string,
          default_value:
            Absinthe.Fixtures.Query.TestSchemaFieldArgDefaultValue.test_function("red")
      end

      field :standard_library_function, :string do
        arg :arg_example, :string, default_value: String.replace("red", "e", "a")
      end

      field :function_in_nested_module, :string do
        arg :arg_example, :string, default_value: NestedModule.nested_function("hello")
      end

      field :external_module_function_call, :string do
        arg :arg_example, :string,
          default_value: Absinthe.Fixtures.FunctionEvaluationHelpers.external_function("hello")
      end

      field :module_attribute_string_concat, :string do
        arg :arg_example, :string, default_value: "hello " <> @module_attribute
      end

      field :interpolation_of_module_attribute, :string do
        arg :arg_example, :string, default_value: "hello #{@module_attribute}"
      end
    end
  end

  defmodule TestSchemaFieldArgDefaultValueWithImportFields do
    use Absinthe.Schema
    @module_attribute "goodbye"

    defmodule NestedModule do
      def nested_function(arg1) do
        arg1
      end
    end

    def test_function(arg1) do
      arg1
    end

    query do
      import_fields :field_arg_default_value
    end

    object :field_arg_default_value do
      field :normal_string, :string do
        arg :arg_example, :string, default_value: "string"
      end

      field :local_function_call, :string do
        arg :arg_example, :string, default_value: test_function("red")
      end

      field :function_call_using_absolute_path_to_current_module, :string do
        arg :arg_example, :string,
          default_value:
            Absinthe.Fixtures.Query.TestSchemaFieldArgDefaultValueWithImportFields.test_function(
              "red"
            )
      end

      field :standard_library_function, :string do
        arg :arg_example, :string, default_value: String.replace("red", "e", "a")
      end

      field :function_in_nested_module, :string do
        arg :arg_example, :string, default_value: NestedModule.nested_function("hello")
      end

      field :external_module_function_call, :string do
        arg :arg_example, :string,
          default_value: Absinthe.Fixtures.FunctionEvaluationHelpers.external_function("hello")
      end

      field :module_attribute_string_concat, :string do
        arg :arg_example, :string, default_value: "hello " <> @module_attribute
      end

      field :interpolation_of_module_attribute, :string do
        arg :arg_example, :string, default_value: "hello #{@module_attribute}"
      end
    end
  end
end
