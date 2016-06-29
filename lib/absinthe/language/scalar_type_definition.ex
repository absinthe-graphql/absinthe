defmodule Absinthe.Language.ScalarTypeDefinition do
  @moduledoc false

  alias Absinthe.Language

  defstruct [
    name: nil,
    directives: [],
    loc: %{start_line: nil}
  ]

  @type t :: %__MODULE__{
    name: binary,
    directives: [Language.Directive.t],
    loc: Language.t
  }

end
