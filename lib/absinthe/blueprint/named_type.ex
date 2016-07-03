defmodule Absinthe.Blueprint.NamedType do

  alias Absinthe.{Phase}

  @enforce_keys [:name]
  defstruct [
    :name,
    errors: []
  ]

  @type t :: %__MODULE__{
    name: String.t,
    errors: [Phase.Error.t]
  }

end
