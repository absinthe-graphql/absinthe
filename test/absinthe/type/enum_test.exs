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

    enum :test_macro_inputting_ast do
      value :red, as: :red, description: hello("red")
    end

    enum :test_function_called_without_name do
      value :red, as: :red, description: Absinthe.Type.EnumTest.TestSchema.hello("red")
    end

    enum :test_standard_function_works do
      value :red, as: :red, description: hello("red")
      String.replace("red", "o", "a")
    end

    enum :test_nested_function do
      value :red, as: :red, description: TestNestedModule.nestedFunction("hello")
    end

    def hello(arg1) do
      arg1
    end
  end

  describe "enums" do
    test "can be defined by a map with defined values" do
      type = TestSchema.__absinthe_type__(:color_channel)
      assert %Type.Enum{} = type

    test "checking if schema works correctly" do
      type = TestSchema.__absinthe_type__(:test_macro_inputting_ast)
      assert %Type.Enum{} = type
      assert %Type.Enum.Value{name: "RED", value: :red, description: "red"} = type.values[:red]
    end

    test "function can be called without module name" do
      type = TestSchema.__absinthe_type__(:test_function_called_without_name)
      assert %Type.Enum{} = type
      assert %Type.Enum.Value{name: "RED", value: :red, description: "red"} = type.values[:red]
    end

    test "calling standard function to ensure it is working correctly" do
      type = TestSchema.__absinthe_type__(:test_standard_function_works)
      assert %Type.Enum{} = type
      assert %Type.Enum.Value{name: "RED", value: :red, description: "a"} = type.values[:red]
    end

    test "function can be called from nested module" do
      type = TestSchema.__absinthe_type__(:test_nested_function)
      assert %Type.Enum{} = type
      assert %Type.Enum.Value{name: "RED", value: :red, description: "hello"} = type.values[:red]
    end
  end
end
