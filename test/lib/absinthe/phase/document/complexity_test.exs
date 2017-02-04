defmodule Absinthe.Phase.Document.Arguments.ComplexityTest do
  use Absinthe.Case, async: true

  alias Absinthe.Blueprint

  defmodule Schema do
    use Absinthe.Schema

    query do
      field :foo_complexity, list_of(:foo) do
        arg :limit, non_null(:integer)

        complexity fn %{limit: limit}, child_complexity ->
          5 + limit * child_complexity
        end
      end
      field :context_aware_complexity, list_of(:foo) do
        complexity penalize_guests(10)
      end
    end

    object :foo do
      field :bar, :string
      field :buzz, :integer
    end

    defp penalize_guests(penalty) do
      fn
        _, child_complexity, %{context: %{current_user: _}} ->
          child_complexity + 1
        _, child_complexity, _ ->
          child_complexity + 1 + penalty
      end
    end

  end

  use Harness.Document.Phase, phase: Absinthe.Phase.Document.Complexity, schema: Schema

  describe "analysing complexity a document" do
    it "uses arguments and defaults to complexity of 1 for a field" do
      doc = """
      query ComplexityArg {
        fooComplexity(limit: 3) {
          bar
        }
      }
      """

      {:ok, result, _} = run_phase(doc, operation_name: "ComplexityArg", variables: %{})
      op = result.operations |> Enum.find(&(&1.name == "ComplexityArg"))
      assert op.complexity == 8
    end

    it "uses variable arguments" do
      doc = """
      query ComplexityVar($limit: Int!) {
        fooComplexity(limit: $limit) {
          bar
          buzz
        }
      }
      """

      {:ok, result, _} = run_phase(doc, operation_name: "ComplexityVar", variables: %{"limit" => 5})
      op = result.operations |> Enum.find(&(&1.name == "ComplexityVar"))
      assert op.complexity == 15
    end

    it "supports access to context" do
      doc = """
      query ContextComplexity {
        contextAwareComplexity {
          bar
          buzz
        }
      }
      """

      {:ok, result, _} = run_phase(doc, operation_name: "ContextComplexity", variables: %{}, context: %{current_user: true})
      op = result.operations |> Enum.find(&(&1.name == "ContextComplexity"))
      assert op.complexity == 3

      {:ok, result, _} = run_phase(doc, operation_name: "ContextComplexity", variables: %{})
      op = result.operations |> Enum.find(&(&1.name == "ContextComplexity"))
      assert op.complexity == 13

    end

    it "uses fragments" do
      doc = """
      query ComplexityFrag {
        fooComplexity(limit: 7) {
          bar
          ... FooFields
        }
      }
      fragment FooFields on Foo {
        buzz
      }
      """

      {:ok, result, _} = run_phase(doc, operation_name: "ComplexityFrag", variables: %{})
      op = result.operations |> Enum.find(&(&1.name == "ComplexityFrag"))
      assert op.complexity == 19
    end

    it "errors when too complex" do
      doc = """
      query ComplexityError {
        fooComplexity(limit: 1) {
          bar
        }
      }
      """

      assert {:error, "complexity is 6, which is above maximum 5", [Absinthe.Phase.Document.Complexity|_]} =
        run_phase(doc, operation_name: "ComplexityError", variables: %{}, max_complexity: 5)
    end
  end
end
