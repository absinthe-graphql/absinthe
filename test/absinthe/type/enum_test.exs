defmodule Absinthe.Type.EnumTest do
  use Absinthe.Case, async: true

  alias Absinthe.Type

  defmodule TestSchema do
    use Absinthe.Schema

    query do
      field :channel, :color_channel, description: "The active color channel" do
        resolve fn _, _ ->
          {:ok, :red}
        end
      end
    end

    enum :color_channel do
      description "The selected color channel"
      value :red, as: :r, description: "Color Red"
      value :green, as: :g, description: "Color Green"
      value :blue, as: :b, description: "Color Blue"

      value :alpha,
        as: :a,
        deprecate: "We no longer support opacity settings",
        description: "Alpha Channel"
    end

    enum :color_channel2 do
      description "The selected color channel"

      value :red, description: "Color Red"
      value :green, description: "Color Green"
      value :blue, description: "Color Blue"

      value :alpha,
        as: :a,
        deprecate: "We no longer support opacity settings",
        description: "Alpha Channel"
    end

    enum :color_channel3,
      values: [:red, :green, :blue, :alpha],
      description: "The selected color channel"

    enum :negative_value do
      value :positive_one, as: 1
      value :zero, as: 0
      value :negative_one, as: -1
    end
  end

  defmodule TestSchemaEnumValueDescriptionKeyword do
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

      value :function_call_using_absolute_path,
        description:
          Absinthe.Type.EnumTest.TestSchemaEnumValueDescriptionKeyword.test_function("red")

      value :standard_library_function, description: String.replace("red", "e", "a")
      value :function_in_nested_module, description: NestedModule.nested_function("hello")

      value :external_module_function_call,
        description: Absinthe.FunctionEvaluationHelpers.external_function("hello")

      value :module_attribute_string_concat, description: "hello " <> @module_attribute
      value :interpolation_of_module_attribute, description: "hello #{@module_attribute}"
    end
  end

  defmodule TestSchemaEnumDescriptionKeyword do
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

    enum :function_call_using_absolute_path,
      description: Absinthe.Type.EnumTest.TestSchemaEnumDescriptionKeyword.test_function("red") do
    end

    enum :standard_library_function, description: String.replace("red", "e", "a") do
    end

    enum :function_in_nested_module, description: NestedModule.nested_function("hello") do
    end

    enum :external_module_function_call,
      description: Absinthe.FunctionEvaluationHelpers.external_function("hello") do
    end

    enum :module_attribute_string_concat, description: "hello " <> @module_attribute do
    end

    enum :interpolation_of_module_attribute, description: "hello #{@module_attribute}" do
    end

    def test_function(arg1) do
      arg1
    end
  end

  defmodule TestSchemaEnumDescriptionAttribute do
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

    # @desc Absinthe.Type.EnumTest.TestSchemaEnumAttribute.test_function("red")
    # enum :function_call_using_absolute_path do
    # end

    @desc String.replace("red", "e", "a")
    enum :standard_library_function do
    end

    @desc NestedModule.nested_function("hello")
    enum :function_in_nested_module do
    end

    @desc Absinthe.FunctionEvaluationHelpers.external_function("hello")
    enum :external_module_function_call do
    end

    @desc "hello " <> @module_attribute
    enum :module_attribute_string_concat do
    end

    @desc "hello #{@module_attribute}"
    enum :interpolation_of_module_attribute do
    end
  end

  defmodule TestSchemaEnumDescriptionMacro do
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

    enum :function_call_using_absolute_path do
      description Absinthe.Type.EnumTest.TestSchemaEnumDescriptionMacro.test_function("red")
    end

    enum :standard_library_function do
      description String.replace("red", "e", "a")
    end

    enum :function_in_nested_module do
      description NestedModule.nested_function("hello")
    end

    enum :external_module_function_call do
      description Absinthe.FunctionEvaluationHelpers.external_function("hello")
    end

    enum :module_attribute_string_concat do
      description "hello " <> @module_attribute
    end

    enum :interpolation_of_module_attribute do
      description "hello #{@module_attribute}"
    end
  end

  describe "enums" do
    test "can be defined by a map with defined values" do
      type = TestSchema.__absinthe_type__(:color_channel)
      assert %Type.Enum{} = type

      assert %Type.Enum.Value{name: "RED", value: :r, description: "Color Red"} =
               type.values[:red]
    end

    test "can be defined by a map without defined values" do
      type = TestSchema.__absinthe_type__(:color_channel2)
      assert %Type.Enum{} = type
      assert %Type.Enum.Value{name: "RED", value: :red} = type.values[:red]
    end

    test "can be defined by a shorthand list of atoms" do
      type = TestSchema.__absinthe_type__(:color_channel3)
      assert %Type.Enum{} = type
      assert %Type.Enum.Value{name: "RED", value: :red, description: nil} = type.values[:red]
    end
  end

  describe "enum value description evaluation" do
    Absinthe.FunctionEvaluationHelpers.function_evaluation_test_params()
    |> Enum.each(fn %{
                      test_label: test_label,
                      expected_description: expected_description
                    } ->
      test "for #{test_label}" do
        type =
          TestSchemaEnumValueDescriptionKeyword.__absinthe_type__(:description_keyword_argument)

        assert type.values[unquote(test_label)].description == unquote(expected_description)
      end
    end)
  end

  describe "enum description keyword evaluation" do
    Absinthe.FunctionEvaluationHelpers.function_evaluation_test_params()
    |> Enum.each(fn %{
                      test_label: test_label,
                      expected_description: expected_description
                    } ->
      test "for #{test_label}" do
        type = TestSchemaEnumDescriptionKeyword.__absinthe_type__(unquote(test_label))
        assert type.description == unquote(expected_description)
      end
    end)
  end

  describe "enum description attribute evaluation" do
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
        type = TestSchemaEnumDescriptionAttribute.__absinthe_type__(unquote(test_label))
        assert type.description == unquote(expected_description)
      end
    end)
  end

  describe "enum description macro evaluation" do
    Absinthe.FunctionEvaluationHelpers.function_evaluation_test_params()
    |> Enum.each(fn %{
                      test_label: test_label,
                      expected_description: expected_description
                    } ->
      test "for #{test_label}" do
        type = TestSchemaEnumDescriptionMacro.__absinthe_type__(unquote(test_label))
        assert type.description == unquote(expected_description)
      end
    end)
  end
end
