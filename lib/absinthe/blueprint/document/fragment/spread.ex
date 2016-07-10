defmodule Absinthe.Blueprint.Document.Fragment.Spread do

  alias Absinthe.Blueprint

  @enforce_keys [:name]
  defstruct [
    :name,
    directives: [],
    source_location: nil,
    # Populated by phases
    errors: [],
  ]

  @type t :: %__MODULE__{
    directives: [Blueprint.Document.Directive.t],
    errors: [Absinthe.Phase.Error.t],
    name: String.t,
    source_location: nil | Blueprint.Document.SourceLocation.t,
  }

end
