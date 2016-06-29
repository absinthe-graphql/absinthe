defmodule Absinthe.Language.InputObjectTypeDefinition do
  @moduledoc false

  defstruct [
    name: nil,
    fields: [],
    directives: [],
    loc: %{start_line: nil},
    errors: [],
    ast_node: nil
  ]

  @type t :: %__MODULE__{
    name: binary,
    fields: [Language.InputValuedDefinition.t],
    directives: [Language.Directive.t],
    loc: Language.loc_t,
    ast_node: Language.t
  }

end
