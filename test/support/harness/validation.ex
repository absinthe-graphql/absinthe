defmodule Support.Harness.Validation do
  import ExUnit.Assertions

  alias Absinthe.{Blueprint, Schema, Phase, Pipeline, Language}
  alias __MODULE__

  @type error_checker_t :: ([{Blueprint.t, Blueprint.Error.t}] -> boolean)

  @spec assert_valid(Schema.t, [Phase.t], Language.Source.t, map) :: no_return
  def assert_valid(schema, rules, document, provided_values) do
    {:ok, result} = run(schema, rules, document, provided_values)
    formatted_errors = Enum.map(error_pairs(result), fn
      {_, error} ->
        error.message
    end)
    assert Enum.empty?(formatted_errors), "Expected no errors, found:\n  ---\n  " <> Enum.join(formatted_errors, "\n  ") <> "\n  ---"
  end

  @spec assert_invalid(Schema.t, [Phase.t], Language.Source.t, map, [error_checker_t] | error_checker_t) :: no_return
  def assert_invalid(schema, rules, document, provided_values, error_checkers) do
    {:ok, result} = run(schema, rules, document, provided_values)
    # IO.inspect(result)
    pairs = error_pairs(result)
    List.wrap(error_checkers)
    |> Enum.each(&(&1.(pairs)))
  end

  @spec assert_passes_rule(Phase.t, Language.Source.t, map) :: no_return
  def assert_passes_rule(rule, document, provided_values) do
    assert_valid(Support.Harness.Validation.Schema, [rule], document, provided_values)
  end

  @spec assert_fails_rule(Phase.t, Language.Source.t, map, [error_checker_t] | error_checker_t) :: no_return
  def assert_fails_rule(rule, document, provided_values, error_checker) do
    assert_invalid(Support.Harness.Validation.Schema, [rule], document, provided_values, error_checker)
  end

  @spec assert_passes_rule_with_schema(Schema.t, Phase.t, Language.Source.t, map) :: no_return
  def assert_passes_rule_with_schema(schema, rule, document, provided_values) do
    assert_valid(schema, [rule], document, provided_values)
  end

  @spec assert_fails_rule_with_schema(Schema.t, Phase.t, Language.Source.t, map, error_checker_t) :: no_return
  def assert_fails_rule_with_schema(schema, rule, document, provided_values, error_checker) do
    assert_invalid(schema, [rule], document, provided_values, error_checker)
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
  defp nodes_with_errors(input) do
    {_, errors} = Blueprint.prewalk(input, [], &do_nodes_with_errors/2)
    errors
  end

  defp error_pairs(input) do
    nodes_with_errors(input)
    |> Enum.flat_map(fn
      %{errors: errors} = node ->
        Enum.map(errors, &{node, &1})
    end)
  end

  defp do_nodes_with_errors(%{errors: []} = node, acc) do
    {node, acc}
  end
  defp do_nodes_with_errors(%{errors: _} = node, acc) do
    {node, [node | acc]}
  end
  defp do_nodes_with_errors(node, acc) do
    {node, acc}
  end

end
