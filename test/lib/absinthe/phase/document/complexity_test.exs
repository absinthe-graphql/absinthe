defmodule Absinthe.Phase.Document.ComplexityTest do
  use Absinthe.Case, async: true

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
      field :discount_child_complexity, list_of(:foo) do
        complexity fn _, child_complexity -> child_complexity - 1 end
      end
      field :nested_complexity, list_of(:quux) do
        complexity fn _, child_complexity ->
          5 * child_complexity
        end
      end
    end

    object :foo do
      field :bar, :string
      field :buzz, :integer
      field :heavy, :string do
        complexity 100
      end
    end

    object :quux do
      field :nested, :foo do
        complexity 1
      end
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

  use Harness.Document.Phase, phase: Absinthe.Phase.Document.Complexity.Result, schema: Schema

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
      errors = result.resolution.validation |> Enum.map(&(&1.message))
      assert errors == []
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
      errors = result.resolution.validation |> Enum.map(&(&1.message))
      assert errors == []
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
      errors = result.resolution.validation |> Enum.map(&(&1.message))
      assert errors == []

      {:ok, result, _} = run_phase(doc, operation_name: "ContextComplexity", variables: %{})
      op = result.operations |> Enum.find(&(&1.name == "ContextComplexity"))
      assert op.complexity == 13
      errors = result.resolution.validation |> Enum.map(&(&1.message))
      assert errors == []

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

    it "raises error on negative complexity" do
      doc = """
      query ComplexityNeg {
        fooComplexity(limit: -20) {
          bar
        }
      }
      """

      assert_raise Absinthe.AnalysisError, fn() ->
        run_phase(doc, operation_name: "ComplexityNeg", variables: %{})
      end
    end


    it "does not error when complex child is discounted by parent" do
      doc = """
      query ComplexityDiscount {
        discountChildComplexity {
          heavy
        }
      }
      """

      {:ok, result, _} = run_phase(doc, operation_name: "ComplexityDiscount", variables: %{}, max_complexity: 100)
      op = result.operations |> Enum.find(&(&1.name == "ComplexityDiscount"))
      assert op.complexity == 99

      errors = result.resolution.validation |> Enum.map(&(&1.message))
      assert errors == []
    end

    it "errors when too complex" do
      doc = """
      query ComplexityError {
        fooComplexity(limit: 1) {
          bar
        }
      }
      """

      {:ok, result, _} = run_phase(doc, operation_name: "ComplexityError", variables: %{}, max_complexity: 5)
      errors = result.resolution.validation |> Enum.map(&(&1.message))
      assert errors == [
        "Field fooComplexity is too complex: complexity is 6 and maximum is 5",
        "Operation ComplexityError is too complex: complexity is 6 and maximum is 5"
      ]
    end

    it "errors when too complex but not for discounted complex child" do
      doc = """
      query ComplexityNested {
        nestedComplexity {
          nested {
            bar
            heavy
          }
        }
      }
      """

      {:ok, result, _} = run_phase(doc, operation_name: "ComplexityNested", variables: %{}, max_complexity: 4)
      errors = result.resolution.validation |> Enum.map(&(&1.message))
      assert errors == [
        "Field nestedComplexity is too complex: complexity is 5 and maximum is 4",
        "Operation ComplexityNested is too complex: complexity is 5 and maximum is 4"
      ]
    end

    it "errors when too complex and nil operation name" do
      doc = """
      {
        fooComplexity(limit: 1) {
          heavy
        }
      }
      """

      {:ok, result, _} = run_phase(doc, operation_name: nil, variables: %{},
      max_complexity: 100)
      errors = result.resolution.validation |> Enum.map(&(&1.message))
      assert errors == [
        "Field fooComplexity is too complex: complexity is 105 and maximum is 100",
        "Operation is too complex: complexity is 105 and maximum is 100"
      ]
    end

    it "skips analysis when disabled" do
      doc = """
      query ComplexitySkip {
        fooComplexity(limit: 3) {
          bar
        }
      }
      """

      {:ok, result, _} = run_phase(doc, operation_name: "ComplexitySkip", variables: %{}, max_complexity: 1, analyze_complexity: false)
      op = result.operations |> Enum.find(&(&1.name == "ComplexitySkip"))
      assert op.complexity == nil
      errors = result.resolution.validation |> Enum.map(&(&1.message))
      assert errors == []
    end

  end
end
