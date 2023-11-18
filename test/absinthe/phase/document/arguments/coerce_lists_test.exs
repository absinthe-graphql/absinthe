defmodule Absinthe.Phase.Document.Arguments.CoerceListsTest do
  use Absinthe.PhaseCase,
    phase: Absinthe.Phase.Document.Arguments.CoerceLists,
    schema: __MODULE__.Schema,
    async: true

  alias Absinthe.Blueprint

  defmodule Schema do
    use Absinthe.Schema

    query do
      field :foo_int_list, :foo do
        arg :input, list_of(:integer)
      end

      field :foo_wrapped_int_list, :foo do
        arg :input, non_null(list_of(non_null(:integer)))
      end

      field :foo_wrapped_enum_list, :foo do
        arg :input, non_null(list_of(non_null(:type)))
      end
    end

    object :foo do
      field :bar, :string
    end

    enum :type do
      value :baz
    end
  end

  describe "when using an List type input argument" do
    test "coerces the type from a single element to List" do
      doc = """
      query List {
        fooIntList(input: 42) {
          bar
        }
      }
      """

      {:ok, result, _} = run_phase(doc, operation_name: "List", variables: %{})
      op = result.operations |> Enum.find(&(&1.name == "List"))
      field = op.selections |> List.first()
      input_argument = field.arguments |> Enum.find(&(&1.name == "input"))

      assert %Blueprint.Input.List{
               items: [%Blueprint.Input.Value{normalized: %Blueprint.Input.Integer{value: 42}}]
             } = input_argument.input_value.normalized
    end

    test "coerces the type from a single element to List when supplying variables" do
      doc = """
      query ListVar($input: Int) {
        fooIntList(input: $input) {
          bar
        }
      }
      """

      {:ok, result, _} = run_phase(doc, operation_name: "ListVar", variables: %{"input" => 42})
      op = result.operations |> Enum.find(&(&1.name == "ListVar"))
      field = op.selections |> List.first()
      input_argument = field.arguments |> Enum.find(&(&1.name == "input"))

      assert %Blueprint.Input.List{
               items: [%Blueprint.Input.Value{normalized: %Blueprint.Input.Integer{value: 42}}]
             } = input_argument.input_value.normalized
    end
  end

  describe "when using a wrapped List type input argument" do
    test "coerces the type from a single element to List" do
      doc = """
      query List {
        fooWrappedIntList(input: 42) {
          bar
        }
      }
      """

      {:ok, result, _} = run_phase(doc, operation_name: "List", variables: %{})
      op = result.operations |> Enum.find(&(&1.name == "List"))
      field = op.selections |> List.first()
      input_argument = field.arguments |> Enum.find(&(&1.name == "input"))

      assert %Blueprint.Input.List{
               items: [%Blueprint.Input.Value{normalized: %Blueprint.Input.Integer{value: 42}}]
             } = input_argument.input_value.normalized
    end

    test "coerces the type from a single element to List when supplying variables" do
      doc = """
      query ListVar($input: Int!) {
        fooWrappedIntList(input: $input) {
          bar
        }
      }
      """

      {:ok, result, _} = run_phase(doc, operation_name: "ListVar", variables: %{"input" => 42})
      op = result.operations |> Enum.find(&(&1.name == "ListVar"))
      field = op.selections |> List.first()
      input_argument = field.arguments |> Enum.find(&(&1.name == "input"))

      assert %Blueprint.Input.List{
               items: [%Blueprint.Input.Value{normalized: %Blueprint.Input.Integer{value: 42}}]
             } = input_argument.input_value.normalized
    end
  end

  describe "when using a List of a coercible type input argument" do
    test "coerces the type from a single element to List" do
      doc = """
      query List {
        fooWrappedEnumList(input: BAZ) {
          bar
        }
      }
      """

      {:ok, result, _} = run_phase(doc, operation_name: "List", variables: %{})
      op = result.operations |> Enum.find(&(&1.name == "List"))
      field = op.selections |> List.first()
      input_argument = field.arguments |> Enum.find(&(&1.name == "input"))

      assert %Blueprint.Input.List{
               items: [%Blueprint.Input.Value{normalized: %Blueprint.Input.Enum{value: "BAZ"}}]
             } = input_argument.input_value.normalized
    end

    test "coerces the type from a single element to List when supplying variables" do
      doc = """
      query ListVar($input: Type!) {
        fooWrappedEnumList(input: $input) {
          bar
        }
      }
      """

      {:ok, result, _} = run_phase(doc, operation_name: "ListVar", variables: %{"input" => "BAZ"})
      op = result.operations |> Enum.find(&(&1.name == "ListVar"))
      field = op.selections |> List.first()
      input_argument = field.arguments |> Enum.find(&(&1.name == "input"))

      assert %Blueprint.Input.List{
               items: [%Blueprint.Input.Value{normalized: %Blueprint.Input.Enum{value: "BAZ"}}]
             } = input_argument.input_value.normalized
    end
  end
end
