defmodule Absinthe.Phase.Document.ComplexityTest do
  use Absinthe.PhaseCase,
    phase: Absinthe.Phase.Document.Complexity.Result,
    schema: __MODULE__.Schema,
    async: true

  defmodule Schema do
    use Absinthe.Schema

    query do
      field :union_complexity, list_of(:search_result) do
        resolve fn _, _ -> {:ok, :foo} end
      end

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

    union :search_result do
      types [:foo, :quux]

      resolve_type fn
        :foo, _ -> :foo
        :quux, _ -> :quux
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

      field :nested_heavy, :foo do
        complexity 100
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

  describe "analysing complexity a document" do
    test "use union" do
      doc = """
      query UnionComplexity {
        unionComplexity {
           ... on Foo {
             bar
             heavy
          }
        }
      }
      """

      assert {:ok, result, _} = run_phase(doc, operation_name: "UnionComplexity", variables: %{})
      op = result.operations |> Enum.find(&(&1.name == "UnionComplexity"))
      assert op.complexity == 102
      errors = result.execution.validation_errors |> Enum.map(& &1.message)
      assert errors == []
    end

    test "uses arguments and defaults to complexity of 1 for a field" do
      doc = """
      query ComplexityArg {
        fooComplexity(limit: 3) {
          bar
        }
      }
      """

      assert {:ok, result, _} = run_phase(doc, operation_name: "ComplexityArg", variables: %{})
      op = result.operations |> Enum.find(&(&1.name == "ComplexityArg"))
      assert op.complexity == 8
      errors = result.execution.validation_errors |> Enum.map(& &1.message)
      assert errors == []
    end

    test "uses variable arguments" do
      doc = """
      query ComplexityVar($limit: Int!) {
        fooComplexity(limit: $limit) {
          bar
          buzz
        }
      }
      """

      assert {:ok, result, _} =
               run_phase(doc, operation_name: "ComplexityVar", variables: %{"limit" => 5})

      op = result.operations |> Enum.find(&(&1.name == "ComplexityVar"))
      assert op.complexity == 15
      errors = result.execution.validation_errors |> Enum.map(& &1.message)
      assert errors == []
    end

    test "supports access to context" do
      doc = """
      query ContextComplexity {
        contextAwareComplexity {
          bar
          buzz
        }
      }
      """

      assert {:ok, result, _} =
               run_phase(
                 doc,
                 operation_name: "ContextComplexity",
                 variables: %{},
                 context: %{current_user: true}
               )

      op = result.operations |> Enum.find(&(&1.name == "ContextComplexity"))
      assert op.complexity == 3
      errors = result.execution.validation_errors |> Enum.map(& &1.message)
      assert errors == []

      assert {:ok, result, _} =
               run_phase(doc, operation_name: "ContextComplexity", variables: %{})

      op = result.operations |> Enum.find(&(&1.name == "ContextComplexity"))
      assert op.complexity == 13
      errors = result.execution.validation_errors |> Enum.map(& &1.message)
      assert errors == []
    end

    test "uses fragments" do
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

      assert {:ok, result, _} = run_phase(doc, operation_name: "ComplexityFrag", variables: %{})
      op = result.operations |> Enum.find(&(&1.name == "ComplexityFrag"))
      assert op.complexity == 19
    end

    test "raises error on negative complexity" do
      doc = """
      query ComplexityNeg {
        fooComplexity(limit: -20) {
          bar
        }
      }
      """

      assert_raise Absinthe.AnalysisError, fn ->
        run_phase(doc, operation_name: "ComplexityNeg", variables: %{})
      end
    end

    test "does not error when complex child is discounted by parent" do
      doc = """
      query ComplexityDiscount {
        discountChildComplexity {
          heavy
        }
      }
      """

      assert {:ok, result, _} =
               run_phase(
                 doc,
                 operation_name: "ComplexityDiscount",
                 variables: %{},
                 max_complexity: 100
               )

      op = result.operations |> Enum.find(&(&1.name == "ComplexityDiscount"))
      assert op.complexity == 99

      errors = result.execution.validation_errors |> Enum.map(& &1.message)
      assert errors == []
    end

    test "errors when too complex" do
      doc = """
      query ComplexityError {
        fooComplexity(limit: 1) {
          bar
        }
      }
      """

      assert {:error, result, _} =
               run_phase(
                 doc,
                 operation_name: "ComplexityError",
                 variables: %{},
                 max_complexity: 5
               )

      errors = result.execution.validation_errors |> Enum.map(& &1.message)

      assert errors == [
               "Field fooComplexity is too complex: complexity is 6 and maximum is 5",
               "Operation ComplexityError is too complex: complexity is 6 and maximum is 5"
             ]
    end

    test "errors when too complex but not for discounted complex child" do
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

      assert {:error, result, _} =
               run_phase(
                 doc,
                 operation_name: "ComplexityNested",
                 variables: %{},
                 max_complexity: 4
               )

      errors = result.execution.validation_errors |> Enum.map(& &1.message)

      assert errors == [
               "Field nestedComplexity is too complex: complexity is 5 and maximum is 4",
               "Operation ComplexityNested is too complex: complexity is 5 and maximum is 4"
             ]
    end

    test "errors when too complex and nil operation name" do
      doc = """
      {
        fooComplexity(limit: 1) {
          heavy
        }
      }
      """

      assert {:error, result, _} =
               run_phase(doc, operation_name: nil, variables: %{}, max_complexity: 100)

      errors = result.execution.validation_errors |> Enum.map(& &1.message)

      assert errors == [
               "Field fooComplexity is too complex: complexity is 105 and maximum is 100",
               "Operation is too complex: complexity is 105 and maximum is 100"
             ]
    end

    test "errors when inline fragment is too complex" do
      doc = """
      query ComplexityInlineFrag {
        unionComplexity {
          ... on Quux {
            ...QuuxFields
          }
        }
      }
      fragment QuuxFields on Quux {
        nested_heavy {
          bar
        }
      }
      """

      assert {:error, result, _} =
               run_phase(
                 doc,
                 operation_name: "ComplexityInlineFrag",
                 variables: %{},
                 max_complexity: 1,
                 schema: Absinthe.Fixtures.ContactSchema
               )

      errors = result.execution.validation_errors |> Enum.map(& &1.message)

      assert errors == [
               "Spread QuuxFields is too complex: complexity is 100 and maximum is 1",
               "Inline Fragment is too complex: complexity is 100 and maximum is 1",
               "Field unionComplexity is too complex: complexity is 101 and maximum is 1",
               "Operation ComplexityInlineFrag is too complex: complexity is 101 and maximum is 1"
             ]
    end

    test "skips analysis when disabled" do
      doc = """
      query ComplexitySkip {
        fooComplexity(limit: 3) {
          bar
        }
      }
      """

      assert {:ok, result, _} =
               run_phase(
                 doc,
                 operation_name: "ComplexitySkip",
                 variables: %{},
                 max_complexity: 1,
                 analyze_complexity: false
               )

      op = result.operations |> Enum.find(&(&1.name == "ComplexitySkip"))
      assert op.complexity == nil
      errors = result.execution.validation_errors |> Enum.map(& &1.message)
      assert errors == []
    end

    test "handles GraphQL introspection" do
      doc =
        [:code.priv_dir(:absinthe), "graphql", "introspection.graphql"]
        |> Path.join()
        |> File.read!()

      assert {:ok, _, _} =
               run_phase(
                 doc,
                 operation_name: "IntrospectionQuery",
                 variables: %{},
                 analyze_complexity: true
               )
    end

    test "__typename doesn't increase complexity" do
      doc_with = """
      query TypenameComplexity {
        fooComplexity(limit: 3) {
          bar
          __typename
        }
      }
      """

      doc_without = """
      query TypenameComplexity {
        fooComplexity(limit: 3) {
          bar
        }
      }
      """

      assert {:ok, result_with, _} =
               run_phase(doc_with, operation_name: "TypenameComplexity", variables: %{})

      op_with = result_with.operations |> Enum.find(&(&1.name == "TypenameComplexity"))
      complexity_with = op_with.complexity

      assert {:ok, result_without, _} =
               run_phase(doc_without, operation_name: "TypenameComplexity", variables: %{})

      op_without = result_without.operations |> Enum.find(&(&1.name == "TypenameComplexity"))
      complexity_without = op_without.complexity

      assert complexity_with == complexity_without
    end
  end
end
