defmodule Absinthe.Language.EnumTypeDefinition do
  @moduledoc false

  alias Absinthe.Language

  defstruct [
    name: nil,
    values: [],
    directives: [],
    loc: %{start_line: nil}
  ]

  @type t :: %__MODULE__{
    name: String.t,
    values: [String.t],
    directives: [Language.Directive.t],
    loc: Language.loc_t,
  }

end
