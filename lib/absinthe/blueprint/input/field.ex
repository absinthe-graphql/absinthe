defmodule Absinthe.Blueprint.Input.Field do

  alias Absinthe.Blueprint

  @enforce_keys [:name, :value]
  defstruct [
    :name,
    :value,
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: String.t,
    value: Blueprint.Input.t,
    errors: [Absinthe.Phase.Error.t],
  }

end
