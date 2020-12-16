defmodule Absinthe.Type.EnumTest do
  use Absinthe.Case, async: true

  alias Absinthe.Type

  defmodule TestSchema do
    use Absinthe.Schema

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
      @module_attribute "goodbye"
      value :test_local_function_call, description: test_function("red")

      value :test_function_is_called_using_path,
        description: Absinthe.Type.EnumTest.TestSchema.test_function("red")

      value :test_standard_library_function_works, description: String.replace("red", "e", "a")
      value :test_function_nested_in_module, description: TestNestedModule.nestedFunction("hello")
      value :test_module_attribute, description: "hello " <> @module_attribute
      value :test_module_attribute_interpolates, description: "hello #{@module_attribute}"
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

    test "local function call" do
      type = TestSchema.__absinthe_type__(:description_keyword_argument)
      assert type.values[:test_local_function_call].description == "red"
    end

    test "function can be called using path" do
      type = TestSchema.__absinthe_type__(:description_keyword_argument)
      assert type.values[:test_function_is_called_using_path].description == "red"
    end

    test "standard function is working correctly" do
      type = TestSchema.__absinthe_type__(:description_keyword_argument)
      assert type.values[:test_standard_library_function_works].description == "rad"
    end

    test "function can be called from nested module" do
      type = TestSchema.__absinthe_type__(:description_keyword_argument)
      assert type.values[:test_function_nested_in_module].description == "hello"
    end

    test "module attribute function is operating correctly" do
      type = TestSchema.__absinthe_type__(:description_keyword_argument)
      assert type.values[:test_module_attribute].description == "hello goodbye"
    end

    test "module attribute interpolates" do
      type = TestSchema.__absinthe_type__(:description_keyword_argument)
      assert type.values[:test_module_attribute_interpolates].description == "hello goodbye"
    end
  end
end
