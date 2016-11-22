defmodule Absinthe.Phase.Document.Arguments.CoercionTest do
  use Absinthe.Case, async: true

  alias Absinthe.Blueprint

  defmodule Schema do
    use Absinthe.Schema

    query do
      field :foo_enum, :foo do
        arg :input, non_null(:type)
      end
      field :foo_list, :foo do
        arg :input, non_null(list_of(non_null(:integer)))
      end
    end

    object :foo do
      field :bar, :string
    end

    enum :type do
      value :baz
    end

  end

  use Harness.Document.Phase, phase: Absinthe.Phase.Document.Arguments.Coercion, schema: Schema

  @query """
    query Enum {
      fooEnum(input: BAZ) {
        bar
      }
    }
    query List {
      fooList(input: 42) {
        bar
      }
    }
    query EnumVar($input: Type!) {
      fooEnum(input: $input) {
        bar
      }
    }
    query ListVar($input: [Int!]!) {
      fooList(input: $input) {
        bar
      }
    }
  """

  describe "when using an Enum type input argument" do
    it "coerces the type from String to Enum" do
      {:ok, result, _} = run_phase(@query, variables: %{})
      op = result.operations |> Enum.find(&(&1.name == "Enum"))
      field = op.selections |> List.first
      input_argument = field.arguments |> Enum.find(&(&1.name == "input"))
      assert %Blueprint.Input.Enum{value: "BAZ"} = input_argument.input_value.normalized
    end

    it "coerces the type from String to Enum when supplying variables" do
      {:ok, result, _} = run_phase(@query, variables: %{"input" => "BAZ"})
      op = result.operations |> Enum.find(&(&1.name == "EnumVar"))
      field = op.selections |> List.first
      input_argument = field.arguments |> Enum.find(&(&1.name == "input"))
      assert %Blueprint.Input.Enum{value: "BAZ"} = input_argument.input_value.normalized
    end
  end

  describe "when using an List type input argument" do
    it "coerces the type from a single element to List" do
      {:ok, result, _} = run_phase(@query, variables: %{})
      op = result.operations |> Enum.find(&(&1.name == "List"))
      field = op.selections |> List.first
      input_argument = field.arguments |> Enum.find(&(&1.name == "input"))
      assert %Blueprint.Input.List{items: [%Blueprint.Input.Value{literal: %Blueprint.Input.Integer{value: 42}}]} = input_argument.input_value.normalized
    end

    it "coerces the type from a single element to List when supplying variables" do
      {:ok, result, _} = run_phase(@query, variables: %{"input" => 42})
      op = result.operations |> Enum.find(&(&1.name == "ListVar"))
      field = op.selections |> List.first
      input_argument = field.arguments |> Enum.find(&(&1.name == "input"))
      assert %Blueprint.Input.List{items: [%Blueprint.Input.Value{literal: %Blueprint.Input.Integer{value: 42}}]} = input_argument.input_value.normalized
    end
  end

end
