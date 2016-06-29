defmodule Absinthe.Language.DirectiveDefinition do
  @moduledoc false

  alias Absinthe.Language

  defstruct [
    name: nil,
    arguments: [],
    directives: [],
    locations: [],
    loc: %{start_line: nil}
  ]

  @type t :: %__MODULE__{
    name: binary,
    directives: [Language.Directive.t],
    arguments: [Language.Argument.t],
    locations: [binary],
    loc: Language.loc_t
  }

end
