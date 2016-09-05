defmodule Absinthe.Phase.Document.Validation do

  @type rule_t :: module

  alias Absinthe.Phase

  @structural_rules [
    Phase.Document.Validation.NoFragmentCycles,
    Phase.Document.Validation.LoneAnonymousOperation,
    Phase.Document.Validation.KnownFragmentNames,
  ]

  @data_rules [
    Phase.Validation.KnownDirectives,
    Phase.Document.Validation.ArgumentsOfCorrectType,
    Phase.Document.Validation.KnownArgumentNames,
    Phase.Document.Validation.ProvidedNonNullArguments,
    Phase.Document.Validation.UniqueArgumentNames,
    Phase.Document.Validation.UniqueInputFieldNames,
  ]

  def structural_pipeline do
    @structural_rules
  end

  def data_pipeline do
    @data_rules
  end

end
