defmodule Absinthe.Blueprint.Input.String do

  alias Absinthe.{Phase}

  @enforce_keys [:value]
  defstruct [
    :value,
    errors: [],
  ]

  @type t :: %__MODULE__{
    value: String.t,
    errors: [Phase.Error.t],
  }

end
