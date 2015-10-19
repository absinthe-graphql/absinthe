defmodule ExGraphQL.Validation do

  alias ExGraphQL.Validation.Rules
  alias ExGraphQL.Language.Node

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

  @spec validate(%ExGraphQL.Type.Schema{}, %ExGraphQL.Language.Document{}) :: :ok | {:error, term}
  @spec validate(%ExGraphQL.Type.Schema{}, %ExGraphQL.Language.Document{}, [atom]) :: :ok | {:error, term}
  def validate(schema, document, rules \\ @specified_rules) do
    context = %ExGraphQL.Validation.Context{schema: schema, document: document}
    errors = rules |> Enum.flat_map &(check(context, document, &1))
    case length(errors) do
      0 -> :ok
      _ -> {:error, errors}
    end
  end

  @spec check(ExGraphQL.Validation.Context.t, Node.t, atom) :: [binary]
  def check(context, node, rule) do
    rule.check(context, node) ++ (node
                                  |> Node.children
                                  |> Enum.flat_map &(check(context, &1, rule)))
  end

end
