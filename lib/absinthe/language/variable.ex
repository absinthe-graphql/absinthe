defmodule Absinthe.Language.Variable do
  @moduledoc false

  alias Absinthe.Language

  defstruct [
    name: nil,
    loc: %{start_line: nil}
  ]

  @type t :: %__MODULE__{
    name: binary,
    loc: Language.loc_t
  }

end
