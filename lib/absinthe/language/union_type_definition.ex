defmodule Absinthe.Language.UnionTypeDefinition do
  @moduledoc false

  defstruct [
    name: nil,
    directives: [],
    types: [],
    loc: %{start_line: nil}
  ]

  @type t :: %__MODULE__{
    name: binary,
    directives: [Language.Directive.t],
    types: [Language.NamedType.t],
    loc: Language.loc_t
  }

end
