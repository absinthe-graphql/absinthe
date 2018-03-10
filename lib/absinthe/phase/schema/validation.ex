defmodule Absinthe.Phase.Schema.Validation do
  @moduledoc false

  alias Absinthe.Phase

  def pipeline do
    [
      Phase.Validation.KnownDirectives
    ]
  end
end
