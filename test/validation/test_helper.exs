defmodule Validation.TestHelper do

  alias Validation.DefaultSchema
  import ExUnit.Assertions

  defp validate(query, %{schema: schema, rules: rules}) do
    source = %ExGraphQL.Language.Source{body: query, name: "Validation.graphql"}
    document = ExGraphQL.parse!(source)
    ExGraphQL.Validation.validate(schema, document, rules)
  end

  defp validate(query, %{schema: schema}) do
    source = %ExGraphQL.Language.Source{body: query, name: "Validation.graphql"}
    document = ExGraphQL.parse!(source)
    ExGraphQL.Validation.validate(schema, document)
  end

  defp validate(query, %{rules: rules} = settings) do
    validate(query, settings |> Map.put(:schema, DefaultSchema.schema))
  end

  defp validate(query) do
    validate(query, %{schema: DefaultSchema.schema})
  end

  # VALID

  defp assert_valid(query) do
    assert :ok = validate(query)
  end
  defp assert_valid(query, settings) do
    assert :ok = validate(query, settings)
  end

  # INVALID

  defp assert_invalid(query) do
    assert {:error, _} = validate(query)
  end
  defp assert_invalid(query, %{schema: schema, rules: rules, errors: errors}) do
    assert {:error, errors} = validate(query, %{schema: schema, rules: rules})
  end
  defp assert_invalid(query, %{rules: rules, errors: errors}) do
    assert {:error, errors} = validate(query, %{rules: rules})
  end
  defp assert_invalid(query, %{schema: schema}) do
    assert {:error, _} = validate(query, %{schema: schema})
  end
  defp assert_invalid(query, %{rules: rules}) do
    assert {:error, _} = validate(query: %{rules: rules})
  end

  # RULES

  def assert_passes_rule(rule, query) do
    assert_valid(query, %{rules: [rule]})
  end

  def assert_fails_rule(rule, query) do
    assert_invalid(query, %{rules: [rule]})
  end

  def assert_fails_rule(rule, query, errors) do
    assert_invalid(query, %{rules: [rule], errors: errors})
  end

end
