defmodule Absinthe.Blueprint.Document.Fragment.Spread do
  @moduledoc false

  alias Absinthe.Blueprint

  @enforce_keys [:name]
  defstruct [
    :name,
    directives: [],
    source_location: nil,
    # Populated by phases
    complexity: nil,
    flags: %{},
    errors: []
  ]

  @type t :: %__MODULE__{
          directives: [Blueprint.Directive.t()],
          errors: [Absinthe.Phase.Error.t()],
          name: String.t(),
          flags: Blueprint.flags_t(),
          source_location: nil | Blueprint.Document.SourceLocation.t()
        }
end
