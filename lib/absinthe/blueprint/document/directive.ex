defmodule Absinthe.Blueprint.Document.Directive do

  alias Absinthe.{Blueprint, Phase}

  @enforce_keys [:name]
  defstruct [
    :name,
    arguments: [],
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: String.t,
    arguments: [Blueprint.Input.Argument.t],
    errors: [Phase.Error.t],
  }

end
