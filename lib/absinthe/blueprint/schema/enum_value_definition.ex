defmodule Absinthe.Blueprint.Schema.EnumValueDefinition do

  alias Absinthe.Blueprint

  @enforce_keys [:value]
  defstruct [
    :value,
    deprecation: nil,
    directives: [],
    source_location: nil,
    # Added by phases
    flags: [],
    errors: [],
  ]

  @type t :: %__MODULE__{
    value: String.t,
    deprecation: nil | Blueprint.Schema.Deprecation.t,
    directives: [Blueprint.Directive.t],
    source_location: nil | Blueprint.Document.SourceLocation.t,
    # Added by phases
    flags: [],
    errors: [Absinthe.Phase.Error.t],
  }

end
