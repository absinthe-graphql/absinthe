defmodule Absinthe.Blueprint.Input.Object do

  alias Absinthe.Blueprint

  @enforce_keys [:fields]
  defstruct [
    fields: [],
    errors: [],
  ]

  @type t :: %__MODULE__{
    fields: [Blueprint.Input.Field.t],
    errors: [Absinthe.Phase.Error.t],
  }

end
