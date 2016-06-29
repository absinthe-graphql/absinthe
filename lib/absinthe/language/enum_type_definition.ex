defmodule Absinthe.Language.EnumTypeDefinition do

  @moduledoc false

  alias Absinthe.Language

  defstruct [
    name: nil,
    values: [],
    loc: %{start_line: nil}
  ]

  @type t :: %__MODULE__{
    name: binary,
    values: [any],
    loc: Language.loc_t
  }

end
