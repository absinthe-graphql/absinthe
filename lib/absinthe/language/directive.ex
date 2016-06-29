defmodule Absinthe.Language.Directive do

  @moduledoc false

  alias Absinthe.Language

  defstruct [
    name: nil,
    arguments: [],
    loc: %{start_line: nil}
  ]

  @type t :: %__MODULE__{
    name: binary,
    arguments: [Language.Argument],
    loc: Language.loc_t
  }

end
