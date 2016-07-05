defmodule Absinthe.Blueprint.Schema.EnumValueDefinition do

  alias Absinthe.Blueprint

  @enforce_keys [:value]
  defstruct [
    :value,
    deprecation: nil,
    errors: [],
  ]

  @type t :: %__MODULE__{
    value: String.t,
    deprecation: nil | Blueprint.Schema.Deprecation.t,
    errors: [Absinthe.Phase.Error.t],
  }

end
