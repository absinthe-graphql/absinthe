defmodule Absinthe.Blueprint.Input.Integer do

  alias Absinthe.{Phase}

  @enforce_keys [:value]
  defstruct [
    :value,
    errors: [],
  ]

  @type t :: %__MODULE__{
    value: integer,
    errors: [Phase.Error.t],
  }

end
