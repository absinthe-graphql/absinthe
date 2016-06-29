defmodule Absinthe.Language.FloatValue do
  @moduledoc false

  alias Absinthe.Language

  defstruct [
    value: nil,
    loc: %{start_line: nil}
  ]

  @type t :: %__MODULE__{
    value: float,
    loc: Language.loc_t
  }

end
