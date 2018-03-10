defmodule Absinthe.Phase.Document.Arguments.CoerceEnumsTest do
  use Absinthe.PhaseCase,
    phase: Absinthe.Phase.Document.Arguments.CoerceEnums,
    schema: __MODULE__.Schema,
    async: true

  alias Absinthe.Blueprint

  defmodule Schema do
    use Absinthe.Schema

    query do
      field :foo_enum, :foo do
        arg :input, :type
      end

      field :foo_non_null_enum, :foo do
        arg :input, non_null(:type)
      end
    end

    object :foo do
      field :bar, :string
    end

    enum :type do
      value :baz
    end
  end

  describe "when using an Enum type input argument" do
    test "coerces the type from String to Enum" do
      doc = """
      query Enum {
        fooEnum(input: BAZ) {
          bar
        }
      }
      """

      {:ok, result, _} = run_phase(doc, operation_name: "Enum", variables: %{})
      op = result.operations |> Enum.find(&(&1.name == "Enum"))
      field = op.selections |> List.first()
      input_argument = field.arguments |> Enum.find(&(&1.name == "input"))
      assert %Blueprint.Input.Enum{value: "BAZ"} = input_argument.input_value.normalized
    end

    test "coerces the type from String to Enum when supplying variables" do
      doc = """
      query EnumVar($input: Type!) {
        fooEnum(input: $input) {
          bar
        }
      }
      """

      {:ok, result, _} = run_phase(doc, operation_name: "EnumVar", variables: %{"input" => "BAZ"})
      op = result.operations |> Enum.find(&(&1.name == "EnumVar"))
      field = op.selections |> List.first()
      input_argument = field.arguments |> Enum.find(&(&1.name == "input"))
      assert %Blueprint.Input.Enum{value: "BAZ"} = input_argument.input_value.normalized
    end
  end

  describe "when using a non-null Enum type input argument" do
    test "coerces the type from String to Enum" do
      doc = """
      query Enum {
        fooNonNullEnum(input: BAZ) {
          bar
        }
      }
      """

      {:ok, result, _} = run_phase(doc, operation_name: "Enum", variables: %{})
      op = result.operations |> Enum.find(&(&1.name == "Enum"))
      field = op.selections |> List.first()
      input_argument = field.arguments |> Enum.find(&(&1.name == "input"))
      assert %Blueprint.Input.Enum{value: "BAZ"} = input_argument.input_value.normalized
    end

    test "coerces the type from String to Enum when supplying variables" do
      doc = """
      query EnumVar($input: Type!) {
        fooNonNullEnum(input: $input) {
          bar
        }
      }
      """

      {:ok, result, _} = run_phase(doc, operation_name: "EnumVar", variables: %{"input" => "BAZ"})
      op = result.operations |> Enum.find(&(&1.name == "EnumVar"))
      field = op.selections |> List.first()
      input_argument = field.arguments |> Enum.find(&(&1.name == "input"))
      assert %Blueprint.Input.Enum{value: "BAZ"} = input_argument.input_value.normalized
    end
  end
end
