defmodule Support.Harness.Validation do
  import ExUnit.Assertions

  alias Absinthe.{Phase, Pipeline}

  def expect_valid(schema, rules, document, provided_values) do
    # TODO
  end

  def expect_invalid(schema, rules, document, provided_values, error_matcher) do
    # TODO
  end

  def expect_passes_rule(rule, document, provided_values) do
    expect_valid(Support.Harness.Validation.Schema, [rule], document, provided_values)
  end

  def expect_fails_rule(rule, document, provided_values, error_matcher) do
    expect_invalid(Support.Harness.Validation.Schema, [rule], document, provided_values, error_matcher)
  end

  def expect_passes_rule_with_schema(schema, rule, document, provided_values) do
    expect_valid(schema, [rule], document, provided_values)
  end

  def expect_fails_rule_with_schema(schema, rule, document, provided_values, error_matcher) do
    expect_invalid(schema, [rule], document, provided_values, error_matcher)
  end

  defp run(schema, rules, document, provided_values) do
    pipeline = pre_validation_pipeline(schema, provided_values)
    Pipeline.run(document, pipeline ++ rules)
  end

  defp pre_validation_pipeline(schema, provided_values) do
    [
      Phase.Parse,
      Phase.Blueprint,
      {Phase.Document.Variables, provided_values},
      Phase.Document.Arguments.Normalize,
      {Phase.Document.Schema, schema},
      Phase.Document.Arguments.Data,
      Phase.Document.Directives
    ]
  end

  # Build a map of node => errors
  defp harvest_errors(input) do
    {result, errors} = Blueprint.prewalk(input, %{}, &do_harvest_errors/2)
    errors
  end

  defp do_harvest_errors(%{errors: []} = node, acc) do
    {node, acc}
  end
  defp do_harvest_errors(%{errors: errors} = node, acc) do
    {node, Map.put(acc, node, errors)}
  end
  defp do_harvest_errors(node, acc) do
    {node, acc}
  end

end
