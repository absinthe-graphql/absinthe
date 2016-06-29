defmodule Absinthe.Language.ObjectTypeDefinition do
  @moduledoc false

  alias Absinthe.Language

  defstruct [
    name: nil,
    directives: [],
    interfaces: [],
    fields: [],
    loc: %{start_line: nil}
  ]

  @type t :: %__MODULE__{
    name: binary,
    directives: [Language.Directive.t],
    interfaces: [Language.NamedType.t],
    fields: [Language.FieldDefinition.t],
    loc: Language.loc_t
  }

end
