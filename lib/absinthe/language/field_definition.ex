defmodule Absinthe.Language.FieldDefinition do
  @moduledoc false

  alias Absinthe.Language

  defstruct [
    name: nil,
    arguments: [],
    directives: [],
    type: nil,
    loc: %{start_line: nil}
  ]

  @type t :: %__MODULE__{
    name: binary,
    arguments: [Language.Argument.t],
    directives: [Language.Directive.t],
    type: Language.type_reference_t,
    loc: Language.loc_t
  }

end
