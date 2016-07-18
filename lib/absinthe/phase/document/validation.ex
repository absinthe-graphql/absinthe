defmodule Absinthe.Phase.Document.Validation do
  alias __MODULE__

  @type rule_t :: module

  @structural_rules [
    Validation.NoFragmentCycles,
  ]

  def structural do
    @structural_rules
  end

end
