defmodule Absinthe.Language.EnumValue do

  @moduledoc false

  alias Absinthe.Language

  defstruct [
    value: nil,
    loc: %{start_line: nil}
  ]

  @type t :: %__MODULE__{
    value: any,
    loc: Language.loc_t
  }

end
