defmodule Absinthe.Phase.Schema.Validation do

  alias Absinthe.Phase

  def pipeline do
    [
      Phase.Validation.KnownDirectives
    ]
  end

end
