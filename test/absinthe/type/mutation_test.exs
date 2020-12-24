defmodule Absinthe.Type.MutationTest do
  use Absinthe.Case, async: true

  defmodule TestSchema do
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
    end

    mutation do
      field :normal_string, :string do
        arg :arg_example, :string, description: "string"
      end

      field :local_function_call, :string do
        arg :arg_example, :string, description: test_function("red")
      end

      field :function_call_using_absolute_path_to_current_module, :string do
        arg :arg_example, :string,
          description: Absinthe.Type.MutationTest.TestSchema.test_function("red")
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

  describe "mutation field arg keyword description evaluation" do
    Absinthe.Fixtures.FunctionEvaluationHelpers.function_evaluation_test_params()
    |> Enum.each(fn %{
                      test_label: test_label,
                      expected_value: expected_value
                    } ->
      test "for #{test_label} (evaluates description to '#{expected_value}')" do
        type = TestSchema.__absinthe_type__("RootMutationType")

        assert type.fields[unquote(test_label)].args.arg_example.description ==
                 unquote(expected_value)
      end
    end)
  end
end
