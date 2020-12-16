defmodule Absinthe.Type.EnumTest do
  use Absinthe.Case, async: true

  alias Absinthe.Type

  defmodule TestSchema do
    use Absinthe.Schema
    @module_attribute "goodbye"

    defmodule TestNestedModule do
      def nestedFunction(arg1) do
        arg1
      end
    end

    query do
      field :channel, :color_channel, description: "The active color channel" do
        resolve fn _, _ ->
          {:ok, :red}
        end
      end
    end

    enum :description_keyword_argument do
      value :normal_string, description: "string"
      value :local_function_call, description: test_function("red")

      value :function_call_using_absolute_path,
        description: Absinthe.Type.EnumTest.TestSchema.test_function("red")

      value :standard_library_function_works, description: String.replace("red", "e", "a")
      value :function_nested_in_module, description: TestNestedModule.nestedFunction("hello")
      value :module_attribute, description: "hello " <> @module_attribute
      value :interpolation_of_module_attribute, description: "hello #{@module_attribute}"
    end

    def test_function(arg1) do
      arg1
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

  @description_tests [
    %{test_label: :normal_string, expected_description: "string"},
    %{test_label: :local_function_call, expected_description: "red"},
    %{test_label: :function_call_using_absolute_path, expected_description: "red"},
    %{test_label: :standard_library_function_works, expected_description: "rad"},
    %{test_label: :function_nested_in_module, expected_description: "hello"},
    %{test_label: :module_attribute, expected_description: "hello goodbye"},
    %{test_label: :interpolation_of_module_attribute, expected_description: "hello goodbye"}
  ]

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

  describe "enum description evaluation" do
    Enum.each(@description_tests, fn %{
                                       test_label: test_label,
                                       expected_description: expected_description
                                     } ->
      test "for #{test_label}" do
        type = TestSchema.__absinthe_type__(:description_keyword_argument)
        assert type.values[unquote(test_label)].description == unquote(expected_description)
      end
    end)
  end
end
