defmodule Absinthe.Blueprint.NonNullType do

  alias Absinthe.Blueprint

  @enforce_keys [:of_type]
  defstruct [
    :of_type,
    errors: []
  ]

  @type t :: %__MODULE__{
    of_type: Blueprint.type_reference_t,
    errors: [Absinthe.Phase.Error.t]
  }


end
