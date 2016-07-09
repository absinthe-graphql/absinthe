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
    name: String.t,
    directives: [Blueprint.Document.Directive.t],
    source_location: nil | Blueprint.Document.SourceLocation.t,
    errors: [Absinthe.Phase.Error.t],
  }

end
