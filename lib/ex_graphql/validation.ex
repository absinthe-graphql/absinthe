defmodule ExGraphQL.Validation do

  alias ExGraphQL.Validation.Rules

  @specified_rules [
    Rules.ArgumentsOfCorrectType,
    Rules.DefaultValuesOfCorrectType,
    Rules.FieldsOnCorrectType,
    Rules.FragmentsOnCompositeTypes,
    Rules.KnownArgumentNames,
    Rules.KnownDirectives,
    Rules.KnownFragmentNames,
    Rules.KnownTypeNames,
    Rules.LoneAnonymousOperation,
    Rules.NoFragmentCycles,
    Rules.NoUndefinedVariables,
    Rules.NoUnusedFragments,
    Rules.NoUnusedVariables,
    Rules.OverlappingFieldsCanBeMerged,
    Rules.PossibleFragmentSpreads,
    Rules.ProvidedNonNullArguments,
    Rules.ScalarLeafs,
    Rules.UniqueArgumentNames,
    Rules.UniqueFragmentNames,
    Rules.UniqueInputFieldNames,
    Rules.UniqueOperationNames,
    Rules.VariablesAreInputTypes,
    Rules.VariablesInAllowedPosition
  ]

  @spec validate(%ExGraphQL.Types.Schema{}, %ExGraphQL.Language.Document{}) :: :ok | {:error, term}
  @spec validate(%ExGraphQL.Types.Schema{}, %ExGraphQL.Language.Document{}, [atom]) :: :ok | {:error, term}
  def validate(schema, document, rules \\ @specified_rules) do
    context = nil
    rules
    |> Enum.map &(&1.visitor(context))
    |> visit(document)
  end

  # Visit an instance
  defp visit(instance, document) do

  end

end
