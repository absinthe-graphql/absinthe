defmodule Absinthe.Language.InterfaceTypeDefinition do
  @moduledoc false

  alias Absinthe.Language

  defstruct [
    name: nil,
    fields: [],
    directives: [],
    loc: %{start_line: nil}
  ]

  @type t :: %__MODULE__{
    name: binary,
    fields: [Language.FieldDefinition.t],
    directives: [Language.Directive.t],
    loc: Language.loc_t
  }

end
