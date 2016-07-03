defmodule Absinthe.Blueprint.Input.Boolean do

  alias Absinthe.Phase

  @enforce_keys [:value]
  defstruct [
    :value,
    errors: [],
  ]

  @type t :: %__MODULE__{
    value: true | false,
    errors: [Phase.Error.t],
  }

end
