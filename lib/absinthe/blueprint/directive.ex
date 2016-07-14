defmodule Absinthe.Blueprint.Directive do

  alias Absinthe.{Blueprint, Phase}

  @enforce_keys [:name]
  defstruct [
    :name,
    arguments: [],
    # When part of a Document
    source_location: nil,
    # Added by phases
    errors: [],
  ]

  @type t :: %__MODULE__{
    name: String.t,
    arguments: [Blueprint.Input.Argument.t],
    source_location: nil | Blueprint.Document.SourceLocation.t,
    errors: [Phase.Error.t],
  }

end
