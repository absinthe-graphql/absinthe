defmodule Absinthe.Blueprint.Input.Argument do

  alias Absinthe.Blueprint

  @enforce_keys [:name, :value]
  defstruct [
    :name,
    :value,
    provided_value: nil,
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: String.t,
    value: Blueprint.Input.t,
    provided_value: Blueprint.Input.t,
    errors: [Absinthe.Phase.Error.t],
  }

end
