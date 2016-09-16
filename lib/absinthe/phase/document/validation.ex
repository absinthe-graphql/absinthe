defmodule Absinthe.Phase.Document.Validation do

  @type rule_t :: module

  alias Absinthe.Phase

  @structural_rules [
    Phase.Document.Validation.NoFragmentCycles,
    Phase.Document.Validation.LoneAnonymousOperation,
    Phase.Document.Validation.SelectedCurrentOperation,
    Phase.Document.Validation.KnownFragmentNames,
    Phase.Document.Validation.NoUndefinedVariables,
    Phase.Document.Validation.NoUnusedVariables,
    Phase.Document.Validation.UniqueFragmentNames,
    Phase.Document.Validation.UniqueOperationNames,
    Phase.Document.Validation.UniqueVariableNames,
  ]

  @data_rules [
    Phase.Validation.KnownDirectives,
    Phase.Document.Validation.ScalarLeafs,    
    Phase.Document.Validation.VariablesAreInputTypes,
    Phase.Document.Validation.ArgumentsOfCorrectType,
    Phase.Document.Validation.KnownArgumentNames,
    Phase.Document.Validation.ProvidedNonNullArguments,
    Phase.Document.Validation.UniqueArgumentNames,
    Phase.Document.Validation.UniqueInputFieldNames,
    Phase.Document.Validation.FieldsOnCorrectType,
  ]

  def structural_pipeline do
    @structural_rules
  end

  def data_pipeline do
    @data_rules
  end

end
