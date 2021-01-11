defmodule Absinthe.Type.QueryTest do
  use Absinthe.Case, async: true

  alias Absinthe.Fixtures.Query

  describe "query field arg keyword description evaluation" do
    Absinthe.Fixtures.FunctionEvaluationHelpers.function_evaluation_test_params()
    |> Enum.each(fn %{
                      test_label: test_label,
                      expected_value: expected_value
                    } ->
      test "for #{test_label} (evaluates description to '#{expected_value}')" do
        type = Query.TestSchemaFieldArgDescription.__absinthe_type__("RootQueryType")

        assert type.fields[unquote(test_label)].args.arg_example.description ==
                 unquote(expected_value)
      end
    end)
  end

  describe "query field arg default_value evaluation" do
    Absinthe.Fixtures.FunctionEvaluationHelpers.function_evaluation_test_params()
    |> Enum.each(fn %{
                      test_label: test_label,
                      expected_value: expected_value
                    } ->
      test "for #{test_label} (evaluates default_value to '#{expected_value}')" do
        type = Query.TestSchemaFieldArgDefaultValue.__absinthe_type__("RootQueryType")
        field = type.fields[unquote(test_label)]

        assert field.args.arg_example.default_value == unquote(expected_value)
      end
    end)
  end

  describe "query field arg default_value evaluation with import_fields" do
    Absinthe.Fixtures.FunctionEvaluationHelpers.function_evaluation_test_params()
    |> Enum.each(fn %{
                      test_label: test_label,
                      expected_value: expected_value
                    } ->
      test "for #{test_label} (evaluates default_value to '#{expected_value}')" do
        type =
          Query.TestSchemaFieldArgDefaultValueWithImportFields.__absinthe_type__("RootQueryType")

        field = type.fields[unquote(test_label)]

        assert field.args.arg_example.default_value == unquote(expected_value)
      end
    end)
  end
end
