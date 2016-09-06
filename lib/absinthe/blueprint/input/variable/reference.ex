defmodule Absinthe.Blueprint.Input.Variable.Reference do

  @enforce_keys [:name, :source_location]
  defstruct [
    :name,
    :source_location,
  ]

  @type t :: %__MODULE__{
    name: String.t,
    source_location: nil | Blueprint.Document.SourceLocation.t,
  }

end
